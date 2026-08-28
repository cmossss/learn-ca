# Self-Assessment — 摸底自测（20 题）

> **怎么用这份自测**
>
> 这不是考试，是**摸底**。目的：找到你的知识缺口在哪，好让 PLAN.md 的节奏更准。
>
> 三条规则：
> 1. **不会就跳**，不要猜。每道题有三种回答方式：完整作答 / 写「听说过但不系统」/ 写「完全没概念」。诚实比答对更重要。
> 2. **允许用电路语言回答**。你是 RTL 工程师，能用时序图、MUX、stall 信号解释的，直接画/直接写，比我更准。
> 3. 每题标了难度 ⬜（应该会）⬜⬜（有印象但要系统化）⬜⬜⬜（可能没接触过）。这只是我的估计，答得好坏不影响它。

**做完后**：把每题的作答情况填到文末的**自评表**，连同作答一起发给我。我会据此调整 Phase 1 的深浅和速度。

---

## Part A：ISA 基础

### Q1. RISC vs CISC（⬜）
RISC 和 CISC 的核心区别是什么？为什么 RISC 用**定长指令**对流水线友好？（提示：可以从译码复杂度、指令执行时间、load-store 架构三个角度想）
RISC指令长度固定，指令格式规整，CISC指令长度和格式不固定。因为定长指令操作码位置固定，所以对流水线友好

### Q2. RV32I 指令编码（⬜⬜）
假设一条指令是 `add x5, x6, x7`：
1. 写出它的 32-bit 编码格式（R-type），标出每个 field 的位置和 bit 宽度（opcode / rd / funct3 / rs1 / rs2 / funct7）。
这个问题我觉得没什么意义，对照指令卡就能写出来，就算是不懂RISCV的人也能做到，我不想花时间去查卡
2. 如果你拿到一个未知的 32-bit 编码，硬件如何判断它是一条 R-type / I-type / S-type / B-type？判断逻辑的关键在哪个 field？
看funct3

### Q3. Addressing modes（⬜）
`register-register`（RR）、`immediate`、`base+offset` 三种寻址方式各适合什么场景？
load/store 架构（RISC）为什么**强制**访存和计算分开（指令不能直接 `add x5, [x6]`）？这在硬件上省掉了什么？
第一种是逻辑运算类指令，操作数都在寄存器中保存，第二种是也是逻辑运算类，一个操作数在寄存器中，另一个是常数，包含在指令中，第三个是访存指令，基地址在寄存器中，偏移地址在指令中。第二个问题不知道怎么回答

### Q4. 控制流指令的数据通路（⬜⬜）
`jal` 和 `jalr` 的**返回地址**和**跳转目标**分别怎么计算？
`jalr` 为什么比 `jal` 多一条数据通路路径（ALU 结果 → PC）？分支（B-type）为什么又是另一条路（adder → PC）？

---

## Part B：流水线

### Q5. 5 级流水线数据通路（⬜⬜）
画出 IF/ID/EX/MEM/WB 五级流水线的**简化数据通路**，标出每一级之间的流水线寄存器（IF/ID、ID/EX、EX/MEM、MEM/WB）。不用画到信号级，画出「数据流 + 每级存了啥」即可。

### Q6. 三类 Hazard（⬜⬜）
用 RTL 语言回答：
1. RAW hazard 的 **forwarding 条件**怎么写？（提示：`EX/MEM.RegWrite && EX/MEM.RegisterRd ≠ 0 && EX/MEM.RegisterRd == ID/EX.RegisterRs1` 这类判断——为什么第一个条件必须是 `RegWrite`？）
2. **load-use stall** 为什么必须 stall 一级？forwarding 能不能救它？为什么不能？

### Q7. 分支 penalty 的定量估算（⬜⬜）
单周期 CPI = 1，理想 5 级流水线 CPI = 1。设每个分支的 penalty 是 2 cycle：
1. 如果分支占比 20%，实际 CPI 是多少？（精确分支损失 = penalty × 分支占比，先算这个）
2. 如果加一个 2-bit predictor，预测正确率 90%（预测错误仍付 2 cycle penalty），CPI 是多少？
3. 从这个算式看，**降低分支损失**有几个杠杆？（正确率 / penalty / 分支占比，哪个你能动、哪个动不了？）

### Q8. 加分支预测器的硬件（⬜⬜⬜）
要在 Lab 1a 的 5 级流水线（无 forward）上加 BTB + 2-bit predictor，**取指阶段**需要哪些额外硬件？
（提示：BTB 存什么？预测正确时 PC 从哪里取？预测错误时怎么恢复？如果 BTB 命中但预测方向错，周期损失几拍？）

---

## Part C：缓存与存储层次

### Q9. Cache 组织方式（⬜⬜）
直接映射 / 组相联 / 全相联三种组织方式的区别？
associativity 升高：命中率上升，但硬件代价是什么？（提示：tag 比较器数量、替换逻辑、面积时序）

### Q10. Cache 地址分解（⬜⬜）
一个 cache：**line size = 64B，4-way set-associative，总容量 256KB，32-bit 地址**。
算出：
1. offset 位数 = ？
2. 一共多少 set = ？
3. set index 位数 = ？
4. tag 位数 = ？
（这个必须会算，后面所有 cache 分析都用它）

### Q11. 写策略（⬜⬜）
`write-through vs write-back`、`write-allocate vs no-write-allocate` 两对策略各自适用什么场景？
为什么 GPU 的 L1/L2 大量使用 **write-back**？（提示：GPU 访存是 write-allocate + 整行读写，write-through 会放大多少带宽？）

### Q12. 3C Model（⬜⬜）
compulsory / capacity / conflict miss 分别是什么？
哪种可以通过**增大 cache**缓解？哪种**不能**？哪种可以通过**提高 associativity** 缓解？

---

## Part D：体系结构深水区（听过就行，答不上很正常）

### Q13. Memory Consistency vs Cache Coherence（⬜⬜⬜）
**一致性（consistency）** 和 **缓存一致性（coherence）** 的区别是什么？（提示：一个管「你观察到的访问顺序」，一个管「多个 cache 对同一地址看到同一份值」）

### Q14. OoO 如何消 WAR/WAW（⬜⬜⬜）
乱序执行怎么消除 **WAR** 和 **WAW** hazard？为什么它**消除不了 RAW**？
用 register renaming + ROB 的角度解释（答不上就写「知道这个名词，机制不熟」即可）。

### Q15. Virtual Memory / TLB（⬜⬜）
page table、TLB、page walk 各是什么？
为什么 **TLB miss** 那么贵（要读多级 page table，几十上百 cycle）？GPU 为什么对 TLB miss 的容忍度比 CPU 高？

### Q16. SMT vs OoO 的延迟隐藏思路（⬜⬜⬜）
同时多线程（SMT）和乱序执行，在**隐藏延迟**上的思路有什么本质不同？
哪个是「把空闲的硬件填满」，哪个是「把指令流内部的并行挖出来」？

---

## Part E：GPGPU 常识

### Q17. SIMT vs SIMD（⬜⬜）
SIMT 和 SIMD 的区别？
为什么 NVIDIA 说自己是 **SIMT 不是 SIMD**？warp 又是什么？（提示：SIMD 是数据级并行，SIMT 是线程级并行 + 硬件广播，各 lane 有自己的 PC 和寄存器堆吗？）

### Q18. GPU 为什么能容忍高延迟（⬜⬜）
CPU 用巨大 cache + 乱序去**降低**访存延迟；GPU 却反着来——**容忍**高延迟。GPU 靠什么补回来？
这跟「GPU 把面积用在更多 ALU 而不是 cache」是什么关系？

### Q19. Memory Coalescing（⬜⬜⬜）
一个 warp（32 个 thread）各自访问一个 4B 的全局地址：
1. 如果 32 个地址**连续**（thread i 访问 address_base + i*4），硬件合并成几个 128B transaction？
2. 如果 32 个地址**跨步 4B×32**（thread i 访问 address_base + i*128），需要几次 transaction？
3. 为什么说 coalescing 是 GPU 访存优化的**头号**手段？

### Q20. Branch Divergence（⬜⬜）
一个 warp 内执行 `if (tid % 2 == 0) A(); else B();`——32 个 thread 中 16 个走 A，16 个走 B。
硬件实际怎么执行？（提示：lane mask、串行执行两条路径、重收敛）
发散对**吞吐**的伤害是什么？（16/32 的 lane 在空转吗？）

---

## 自评表（做完填这个）

对每题三选一：✅ 完整作答 / ◐ 听说过但不系统 / ❌ 完全没概念。

| 题号 | 状态 | 一句话：卡在哪 / 哪里不确定 |
|---|---|---|
| Q1 | 听说过但不系统| |
| Q2 |完整作答 |需要查指令手册 |
| Q3 |听说过但不系统 |知道三种寻址方式的含义，但是不知道为什么要这样 |
| Q4 |听说过但不系统 |之前看过但是忘记了 |
| Q5 |听说过但不系统| |
| Q6 |完全没概念 | |
| Q7 |完全没概念 | |
| Q8 |完全没概念 | |
| Q9 |完全没概念 | |
| Q10 |完全没概念 | |
| Q11 |完全没概念 | |
| Q12 |完全没概念 | |
| Q13 |完全没概念 | |
| Q14 |完全没概念 | |
| Q15 |完全没概念 | |
| Q16 |完全没概念 | |
| Q17 |完全没概念 | |
| Q18 |完全没概念 | |
| Q19 |完全没概念 | |
| Q20 |完全没概念 | |

**汇总**（把每块 ✅ 的数量填进去）：

| Part | 主题 | ✅ 数 / 题数 | 结论 |
|---|---|---|---|
| A | ISA | 1/4 | 系统学过？还是零星印象？ |
| B | 流水线 | 0/4 | 硬件直觉能不能撑住定量分析？ |
| C | 缓存 |0/4 | 组织方式熟了，写策略/3C 呢？ |
| D | 深水区 | 0/4 | 这块是 Phase 1 后半 + Phase 3 的地基 |
| E | GPGPU | 0/4 | 进 Phase 2 前的起点 |

> **我怎么用你的结果**：✅ 多的部分，Phase 1 对应章节可以快进；◐ 多的部分，那周的 lab 我会加讲解；❌ 多的部分不丢人，本来就是计划里要补的。把自评表发我，我们据此微调第一周的内容。
