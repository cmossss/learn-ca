# ============================================================
# t02_fib.S —— 循环与分支
#
# 验证范围：所有条件分支 + 无条件跳转 + 循环控制
# 计算：fib(20) = 6765
# 期望输出：=== PASS ===
#
# 覆盖指令：
#   B-type : beq bne blt bge bltu bgeu
#   J-type : jal（j 是 jal x0, 的伪指令）
#
# 重点：signed / unsigned 的区别。程序里故意用 -1（= 0xffffffff）
#       和 1 做比较 —— 有符号下 -1 < 1，无符号下 0xffffffff > 1。
#       如果 CPU 的 slt / 分支没区分符号位，这两组断言会挂。
# ============================================================

    .text
    .globl _start

    .equ RESULT_ADDR, 0x100
    .equ TOHOST_ADDR, 0x200

.macro CHECK reg, expected, id
    li   t6, \id
    li   t0, \expected
    bne  \reg, t0, fail
.endm

_start:
    # ---------------- 1. 循环：算 fib(20) ----------------
    li   a0, 0               # f(0)
    li   a1, 1               # f(1)
    li   a2, 19              # 每迭代一次往前推一格，19 次后 a1 = f(20)
    li   a3, 0               # i

fib_loop:
    bge  a3, a2, fib_done
    add  a4, a0, a1          # f_next = f(i) + f(i+1)
    mv   a0, a1
    mv   a1, a4
    addi a3, a3, 1
    j    fib_loop

fib_done:
    CHECK a1, 6765, 1        # fib(20)

    # ---------------- 2. 各分支形式 ----------------
    li   t1, 5
    li   t2, 5
    li   t3, 3
    li   t4, -1              # 0xffffffff
    li   t5, 1

    # ---- 应当「跳转」的分支：跳了就跨过 j fail，没跳就 fail ----
    # 用汇编器的数字局部标签：1f = 往后的第一个 "1:"，可以重复用
    li   t6, 2
    beq  t1, t2, 1f          # 5 == 5
    j    fail
1:
    li   t6, 3
    bne  t1, t3, 1f          # 5 != 3
    j    fail
1:
    li   t6, 4
    blt  t3, t1, 1f          # 3 <  5（有符号）
    j    fail
1:
    li   t6, 5
    blt  t4, t3, 1f          # -1 < 3（有符号）★ 按无符号判会错
    j    fail
1:
    li   t6, 6
    bge  t1, t2, 1f          # 5 >= 5
    j    fail
1:
    li   t6, 7
    bltu t3, t1, 1f          # 3 <u 5
    j    fail
1:
    li   t6, 8
    bgeu t1, t3, 1f          # 5 >=u 3
    j    fail
1:
    li   t6, 9
    bltu t5, t4, 1f          # 1 <u 0xffffffff ★ 按有符号判会错
    j    fail
1:
    li   t6, 10
    bgeu t4, t5, 1f          # 0xffffffff >=u 1 ★
    j    fail
1:

    # ---- 应当「不跳转」的分支：跳了就 fail，没跳就自然往下走 ----
    li   t6, 11
    beq  t1, t3, fail        # 5 == 3 为假
    li   t6, 12
    bne  t1, t2, fail        # 5 != 5 为假
    li   t6, 13
    blt  t1, t3, fail        # 5 <  3 为假
    li   t6, 14
    bge  t3, t1, fail        # 3 >= 5 为假
    li   t6, 15
    bltu t4, t5, fail        # 0xffffffff <u 1 为假
    li   t6, 16
    bgeu t5, t4, fail        # 1 >=u 0xffffffff 为假

    li   a0, 0
    j    pass


pass:
    li   t1, RESULT_ADDR
    sw   a0, 0(t1)
    li   t0, 1
    li   t1, TOHOST_ADDR
    sw   t0, 0(t1)
1:  j    1b

fail:
    li   t1, RESULT_ADDR
    sw   t6, 0(t1)           # 结果留档 = 失败的 CHECK 编号
    slli t0, t6, 1           # tohost = (check << 1) | 1
    ori  t0, t0, 1           #   ^ riscv-tests 的标准失败约定
    li   t1, TOHOST_ADDR
    sw   t0, 0(t1)
1:  j    1b
