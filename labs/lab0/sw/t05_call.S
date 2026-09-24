# ============================================================
# t05_call.S —— 函数调用：jal / jalr / 栈
#
# 验证范围：返回地址的写回、嵌套调用时 ra 的保存与恢复、栈指针平衡
# 期望输出：=== PASS ===
#
# 覆盖指令：
#   jal  ra, label    —— 写回 PC+4，跳到 label
#   jalr ra, 0(rs1)   —— 用寄存器算目标地址（ret 就是这个的伪指令）
#
# ★ 这块最容易被漏掉。只实现 jal 不实现 jalr 的话，Lab 0 的测试可能还能过，
#   但等你后面拿 riscv-tests 或自己写的 C 代码来跑，会直接卡死 —— 因为
#   函数返回全靠 jalr。
#
# 另一个易错点：jalr 的目标地址要清掉最低位（spec 里写的是
#   pc = (rs1 + imm) & ~1
#   RV32I 里指令本来就不会落在奇地址，但这一位不清，某些测试会挂。
# ============================================================

    .text
    .globl _start

    .equ RESULT_ADDR, 0x100
    .equ TOHOST_ADDR, 0x200
    .equ STACK_TOP,  0x1000  # 栈顶，向下增长

.macro CHECK reg, expected, id
    li   t6, \id
    li   t0, \expected
    bne  \reg, t0, fail
.endm

.macro CHECK_REG reg, expected_reg, id
    li   t6, \id
    bne  \reg, \expected_reg, fail
.endm

_start:
    li   sp, STACK_TOP

    # ---------------- 1. 单层调用 ----------------
    li   a0, 7
    li   a1, 6
    jal  ra, add_fn          # a0 = a0 + a1 = 13
    CHECK a0, 13, 1

    # ---------------- 2. 嵌套调用：验证 ra 的保存/恢复 ----------------
    li   a0, 10
    jal  ra, outer_fn        # a0 = square(10) + square(10) = 200
    CHECK a0, 200, 2

    # ---------------- 3. jalr 寄存器间接跳转 ----------------
    lla  t1, target_fn       # 注意是 lla 不是 la（裸机下 la 会走 GOT，见 t01 注释）
    jalr ra, 0(t1)
    CHECK a0, 42, 3

    # ---------------- 4. 栈必须回到原位 ----------------
    li   t1, STACK_TOP
    CHECK_REG sp, t1, 4

    li   a0, 0
    j    pass


# ============================================================
# 函数区
# ============================================================

# a0 = a0 + a1
add_fn:
    add  a0, a0, a1
    ret                      # 伪指令 -> jalr x0, 0(ra)

# a0 = n^2（用累加实现，RV32I 没有 mul）
# 需要保存 ra —— 但这里不调用别人，所以其实不用存。
# 留着这一层是为了和 outer_fn 对比。
square_fn:
    mv   t2, a0              # n
    li   t3, 0               # acc
sq_loop:
    blez t2, sq_done
    add  t3, t3, a0
    addi t2, t2, -1
    j    sq_loop
sq_done:
    mv   a0, t3
    ret

# a0 = 2 * n^2
# 会调用 square_fn 两次 —— 必须把 ra 和用到的 s 寄存器存到栈上
outer_fn:
    addi sp, sp, -16
    sw   ra, 0(sp)
    sw   s2, 4(sp)
    sw   s3, 8(sp)

    mv   s3, a0              # 保住 n
    jal  ra, square_fn       # ra 在这里被覆盖
    mv   s2, a0              # 第一次结果
    mv   a0, s3              # 恢复 n
    jal  ra, square_fn       # 第二次
    add  a0, a0, s2

    lw   ra, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    addi sp, sp, 16
    ret

# 只用来测 jalr
target_fn:
    li   a0, 42
    ret


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
