# ============================================================
# t01_alu.S —— ALU 与立即数
#
# 验证范围：不碰内存、不跳转（除 pass/fail），只走
#           fetch -> decode -> regfile 读 -> ALU -> 写回
# 期望输出：tb 打印 === PASS ===
#
# 覆盖指令：
#   R-type : add sub and or xor sll srl sra slt sltu
#   I-type : addi andi ori xori slti sltiu slli srli srai
#   U-type : lui auipc
# ============================================================

    .text
    .globl _start

    .equ RESULT_ADDR, 0x100
    .equ TOHOST_ADDR, 0x200

# ---- 断言宏 ----------------------------------------------------
# CHECK <寄存器>, <期望值>, <编号>
#   不成立就跳到 fail，t6 里带着失败编号
#   注意：t0 / t6 被宏占用，测试代码里别拿它们存东西
.macro CHECK reg, expected, id
    li   t6, \id
    li   t0, \expected
    bne  \reg, t0, fail
.endm

_start:
    li   a0, 5
    li   a1, 3

    # ---------------- R-type ----------------
    add  a2, a0, a1          # 5 + 3
    CHECK a2, 8, 1
    sub  a3, a0, a1          # 5 - 3
    CHECK a3, 2, 2
    and  a4, a0, a1          # 5 & 3 = 1
    CHECK a4, 1, 3
    or   a5, a0, a1          # 5 | 3 = 7
    CHECK a5, 7, 4
    xor  a6, a0, a1          # 5 ^ 3 = 6
    CHECK a6, 6, 5

    sll  s0, a0, a1          # 5 << 3 = 40
    CHECK s0, 40, 6
    srl  s1, s0, a1          # 40 >> 3 = 5（逻辑右移）
    CHECK s1, 5, 7

    li   s2, -16             # 0xfffffff0
    CHECK s2, -16, 8
    sra  s3, s2, a1          # -16 >>> 3 = -2（算术右移）
    CHECK s3, -2, 9
    srl  s4, s2, a1          # 0xfffffff0 >> 3 = 0x1ffffffe（逻辑右移）
    CHECK s4, 0x1ffffffe, 10

    slt  s5, a1, a0          # 3 <  5 = 1
    CHECK s5, 1, 11
    slt  s6, a0, a1          # 5 <  3 = 0
    CHECK s6, 0, 12
    sltu s7, s2, a0          # 0xfffffff0 <u 5 = 0（无符号比较的关键用例）
    CHECK s7, 0, 13

    # ---------------- I-type ----------------
    addi a2, a0, -10         # 5 - 10
    CHECK a2, -5, 14
    andi a3, a0, 3           # 5 & 3
    CHECK a3, 1, 15
    ori  a4, a0, 8           # 5 | 8
    CHECK a4, 13, 16
    xori a5, a0, 1           # 5 ^ 1
    CHECK a5, 4, 17
    slti a6, a0, 10          # 5 < 10（有符号）
    CHECK a6, 1, 18
    sltiu a7, s2, 10         # 0xfffffff0 <u 10 = 0
    CHECK a7, 0, 19

    slli t1, a0, 4           # 5 << 4 = 80
    CHECK t1, 80, 20
    srli t2, s2, 4           # 0xfffffff0 >> 4 = 0x0fffffff
    CHECK t2, 0x0fffffff, 21
    srai t3, s2, 4           # 0xfffffff0 >>> 4 = 0xffffffff（-1）
    CHECK t3, -1, 22

    # ---------------- U-type ----------------
    lui  t4, 0x12345         # t4 = 0x12345000
    CHECK t4, 0x12345000, 23

    li   t5, 0xdeadbeef      # 伪指令；注意高位置 1，测一下大立即数
    CHECK t5, 0xdeadbeef, 24

    # auipc：s8 = 本条 auipc 指令自己的地址
    # 注意用 lla 而不是 la：裸机链接下 la 会走 GOT（展开成 auipc + lw），
    # 而我们的程序没有 GOT，取出来是 0。lla 才是干净的 auipc + addi。
auipc_here:
    auipc s8, 0
    lla   s9, auipc_here
    li    t6, 25
    bne   s8, s9, fail

    # ---------------- 全过 ----------------
    li   a0, 0               # a0 = 0 表示 all pass
    j    pass


# ============================================================
# 结果上报 —— 所有测试程序结尾都一样，与 tb/tb_top.sv 约定：
#   RESULT_ADDR (0x100)  tb 打印这个值，不结束仿真
#   TOHOST_ADDR (0x200)  写 1 => PASS；写 (check<<1)|1 => FAIL 并报出编号
# ============================================================
pass:
    li   t1, RESULT_ADDR
    sw   a0, 0(t1)           # 结果留档
    li   t0, 1
    li   t1, TOHOST_ADDR
    sw   t0, 0(t1)
1:  j    1b                  # tb 捕获到 tohost 后会 $finish，这里兜底

fail:
    li   t1, RESULT_ADDR
    sw   t6, 0(t1)           # 结果留档 = 失败的 CHECK 编号
    slli t0, t6, 1           # tohost = (check << 1) | 1
    ori  t0, t0, 1           #   ^ riscv-tests 的标准失败约定
    li   t1, TOHOST_ADDR
    sw   t0, 0(t1)
1:  j    1b
