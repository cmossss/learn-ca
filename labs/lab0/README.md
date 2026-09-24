# Lab 0 —— RV32I 单周期处理器

**目标**：用 RTL 实现一个能跑真实 RISC-V 程序的单周期 CPU，跑通 5 个测试程序。

**为什么先做这个**：后面 Lab 1（流水线）、Lab 3（cache）都要往这个核上挂。先把「一条指令怎么从取指走到写回」跑通，流水线的 hazard 才有地方落。

**参考**：Patterson & Hennessy《Computer Organization and Design》RISC-V 版 **Ch.4 "The Processor"** —— 这一章讲的就是单周期数据通路，照着书上的图翻译成 RTL 即可。

---

## 1. 你要做的事

只有一件事：**填 `rtl/rv32i_core.sv`**。

其他所有东西（汇编器、链接脚本、hex 转换、testbench、存储器模型、5 个测试程序）都已经搭好并验证过了。

验收标准：

```bash
make test
```

5 个测试全部 PASS。

> 第一次 `make sim` 一定是 `=== TIMEOUT ===` —— 因为空壳里 PC 不动。**那就是正确的起点。**

---

## 2. 接口约定（和 tb 对齐，不要改）

```systemverilog
module rv32i_core (
    input  logic        clk,
    input  logic        rst_n,        // 低有效异步复位

    output logic [31:0] imem_addr,    // 取指地址 = PC
    input  logic [31:0] imem_rdata,   // 组合读：地址给出，当拍数据就回来

    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic [ 3:0] dmem_wstrb,   // 字节使能，逐字节写
    output logic        dmem_we,
    input  logic [31:0] dmem_rdata    // 组合读
);
```

**两条硬性约定**（这是「单周期」的定义）：

1. **imem / dmem 都是组合读** —— 你给出地址，当拍数据就回来。中间没有握手、没有 ready 信号。
   （等你做 Lab 1a 的流水线版本时才需要改这个模型，到时候 tb 也要一起改。）
2. **dmem 是同步写** —— 在时钟上升沿，按 `dmem_wstrb` **逐字节**写入。
   `dmem_wstrb` 没置位的字节**必须保持不变**。`sw` 置 4 位、`sh` 置 2 位、`sb` 置 1 位。

存储器布局（Harvard：指令内存和数据内存是两块独立的）：

| | 大小 | 地址 | 说明 |
|---|---|---|---|
| imem | 4096 words | `0x0000` 起 | `$readmemh` 从 `.hex` 加载 |
| dmem | 4096 words | `0x0000` 起 | 程序用 `sw` 自己写 |

因为 imem / dmem 是分开的，**程序里不能定义初始化数据数组再用 `lw` 去读** —— 那读的是 dmem，不是 imem。所有测试数据都是程序运行时用 `sw` 现写进去的。

---

## 3. 常用命令

```bash
make                       # 看帮助
make sim  PROG=t02_fib     # 跑一个测试，打印 PASS/FAIL
make wave PROG=t02_fib     # 跑仿真 + dump 波形 + 打开 gtkwave
make dis  PROG=t02_fib     # 反汇编（对着波形看指令）
make test                  # 5 个测试全跑  ← 验收命令
make clean
```

调试时加 `+trace` 逐条打印前 400 条指令：

```bash
build/obj_sim/sim +prog=$PWD/build/t02_fib.hex +trace | head -40
```

---

## 4. 测试程序清单

按这个顺序做，每个新实现一块通路就跑一次。

| 程序 | 覆盖指令 | 验证什么 |
|---|---|---|
| `t01_alu` | `add sub and or xor sll srl sra slt sltu`<br>`addi andi ori xori slti sltiu slli srli srai`<br>`lui auipc` | 纯 ALU 通路。**最容易挂的是 `sra`/`srai` 的算术右移**（别写成逻辑右移）和 `slt`/`sltu` 的符号位 |
| `t02_fib` | `beq bne blt bge bltu bgeu` `jal` | 所有分支形式。故意用 -1 和 1 做比较，**符号位判错会挂** |
| `t03_mem` | `sw sh sb` `lw lh lhu lb lbu` | 字节使能、小端序、符号扩展 vs 零扩展、非对齐地址（`lbu t4, 1(s0)` 这种） |
| `t04_sort` | 嵌套循环 + 以上全部 | 综合：冒泡排序 16 个数 |
| `t05_call` | `jal` `jalr` `ret` | 函数调用、`ra` 的保存恢复、栈平衡。**`jalr` 最容易漏**，漏了后面跑什么都卡死 |

每个程序结束时会往两个「魔法地址」写：

| 地址 | 含义 |
|---|---|
| `0x100` | `RESULT`：结果值 / 失败的 CHECK 编号。tb 打印，不结束 |
| `0x200` | `TOHOST`：写 `1` = PASS；写 `(check<<1)|1` = FAIL。tb 收到就 `$finish` |

这就是 **riscv-tests 的标准 tohost 约定** —— 以后你跑 RISC-V 官方测试套件时是同一套机制。

失败时的输出长这样，直接告诉你哪条 CHECK 挂了：

```
[355000] RESULT = 7  (0x00000007)
=== FAIL === 第 7 条 CHECK 挂了
```

然后 `grep -n "CHECK .*, 7$" sw/t01_alu.S` 就能定位到断言。

---

## 5. 实现顺序建议

按这个顺序做，每步都能跑一次 `make test` 看进展：

- [ ] **1. PC 寄存器** —— 复位到 0，每拍 `PC <= PC + 4`。做完 `make sim` 应该看到 PC 在推进（`+trace` 能看出来），不再原地打转
- [ ] **2. 译码器** —— `opcode` / `funct3` / `funct7` → 控制信号
- [ ] **3. 立即数生成器** —— I / S / B / U / J 五种格式。**这是最容易写错的一块**，建议单独写个 `always_comb` 一眼能看清位拼接
- [ ] **4. 寄存器堆** —— 2 读 1 写，`x0` 恒为 0（写 x0 要丢弃）
- [ ] **5. ALU** —— 先做 `t01`，做到 PASS
- [ ] **6. next-PC 逻辑** —— 分支 / `jal` / `jalr`。做到 `t02` PASS
      ⚠️ `jalr` 的目标地址要清最低位：`pc = (rs1 + imm) & ~1`
- [ ] **7. load/store** —— 字节使能 + 符号/零扩展。做到 `t03` PASS
      ⚠️ load/store 的**地址计算永远走加法**，不要复用指令的 ALU 译码
      （`sw` 的 funct3 = `010`，如果 ALU 译码器按 funct3 干活会把它当成 `slt`）
- [ ] **8. 写回 MUX** —— ALU 结果 / `dmem_rdata` / `PC+4`
- [ ] **9. `make test` 全绿**

---

## 6. 调试建议

- **先看波形**。`make wave PROG=t01_alu`，在 gtkwave 里把 `pc` / `instr` / 各控制信号 / `alu_result` / `dmem_*` 拖出来。单周期 CPU 的波形非常直观：一拍一条指令，从头到尾一条组合链。
- **`+trace` 对着 `make dis` 看**。两个并排，能一眼定位到哪条指令开始跑偏。
- **TIMEOUT 时看 tb 打印的「最后 PC」**，反查反汇编就知道卡在哪。
- **`x0` 一定不能写进去**。如果某个测试莫名其妙挂了，先查这个。
- **符号扩展**。`lb`/`lh` 要符号扩展，`lbu`/`lhu` 要零扩展，`lw` 不用扩展。`sra`/`srai` 是算术右移。这几处是 RV32I 实现 bug 的重灾区。

---

## 7. 目录结构

```
labs/lab0/
├── Makefile           # 全流程：汇编 -> hex -> verilator -> PASS/FAIL
├── README.md
├── rtl/
│   └── rv32i_core.sv  ← ★ 你的作业（现在是空壳）
├── tb/
│   └── tb_top.sv      # 测试平台：时钟/复位、存储器模型、tohost 监视、超时
├── sw/
│   ├── link.ld        # 裸机链接脚本
│   ├── bin2hex.py     # .bin -> $readmemh 能吃的 .hex
│   └── t01..t05.S     # 5 个测试程序
└── build/             # 生成物（不进 git）
```

### 工具链说明

用的是系统自带的 `riscv64-linux-gnu-gcc`，靠这几个 flag 当裸机编译器使：

```
-march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -no-pie
-Wl,--build-id=none -Wl,--no-warn-rwx-segments -T sw/link.ld
```

那个 `-no-pie` 不能省 —— Ubuntu 的交叉工具链默认开 PIE，不加会报 `PHDR segment not covered by LOAD segment`，看起来像链接脚本写错了，其实不是。

**写新汇编时注意**：取标签地址用 `lla` 不要用 `la`。裸机下 `la` 会走 GOT（展开成 `auipc` + `lw`），而我们的程序没有 GOT，取出来是 0。这个坑在 `t01_alu.S` 的注释里记着。
