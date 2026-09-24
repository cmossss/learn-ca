# ============================================================
# t03_mem.S —— load / store 与字节使能
#
# 验证范围：数据内存通路、小端字节序、符号/零扩展、负偏移寻址
# 期望输出：=== PASS ===
#
# 覆盖指令：
#   store : sw sh sb
#   load  : lw lh lhu lb lbu
#
# 最容易写错的两处：
#   1. dmem_wstrb —— sw 写 4 字节、sh 写 2 字节、sb 写 1 字节，
#      其余字节必须保持不变。很多人的第一版会把整个字写进去。
#   2. lb / lh 要「符号扩展」，lbu / lhu 要「零扩展」。
# ============================================================

    .text
    .globl _start

    .equ RESULT_ADDR, 0x100
    .equ TOHOST_ADDR, 0x200

# ==== 断言宏 ====
# CHECK <寄存器>, <期望值>, <编号>
#   不成立就跳到 fail，t6 里带着失败编号
#   ★ t0 / t6 被宏占用，测试代码里不要拿它们当数据寄存器 ★
.macro CHECK reg, expected, id
    li   t6, \id
    li   t0, \expected
    bne  \reg, t0, fail
.endm

_start:
    li   s0, 0x400           # 数据区基址（避开 0x100 / 0x200 两个魔法地址）

    # ---------------- 1. 字读写 + 小端字节序 ----------------
    li   t1, 0x12345678
    sw   t1, 0(s0)
    lw   t2, 0(s0)
    CHECK t2, 0x12345678, 1

    lbu  t3, 0(s0)           # 最低地址 = 最低字节 = 0x78
    CHECK t3, 0x78, 2
    lbu  t4, 1(s0)           # 0x56
    CHECK t4, 0x56, 3
    lbu  t5, 2(s0)           # 0x34
    CHECK t5, 0x34, 4
    lbu  a1, 3(s0)           # 0x12
    CHECK a1, 0x12, 5

    lhu  t1, 0(s0)           # 低半字 0x5678
    CHECK t1, 0x5678, 6
    lhu  t2, 2(s0)           # 高半字 0x1234
    CHECK t2, 0x1234, 7

    # ---------------- 2. 符号扩展 vs 零扩展 ----------------
    sw   zero, 4(s0)         # 先把这 4 字节清零
    li   t1, 0xff
    sb   t1, 4(s0)           # 只写最低字节
    lw   t2, 4(s0)           # 其余字节应保持 0
    CHECK t2, 0x000000ff, 8

    lbu  t3, 4(s0)           # 零扩展 -> 0x000000ff
    CHECK t3, 0xff, 9
    lb   t4, 4(s0)           # 符号扩展 -> 0xffffffff = -1
    CHECK t4, -1, 10

    li   t1, 0x8000
    sh   t1, 8(s0)           # 写入半字 0x8000
    lhu  t5, 8(s0)           # 零扩展 -> 0x00008000
    CHECK t5, 0x8000, 11
    lh   a1, 8(s0)           # 符号扩展 -> 0xffff8000 = -32768
    CHECK a1, -32768, 12

    # ---------------- 3. 字节使能：部分写不能碰其余字节 ----------------
    li   t1, 0xaabbccdd
    sw   t1, 12(s0)          # 内存: dd cc bb aa
    li   t2, 0x11
    sb   t2, 13(s0)          # 只覆盖第 2 个字节
    lw   t3, 12(s0)          # 期望 0xaabb11dd
    CHECK t3, 0xaabb11dd, 13

    li   t1, 0xbeef
    sh   t1, 14(s0)          # 覆盖高 2 个字节
    lw   t2, 12(s0)          # 期望 0xbeef11dd
    CHECK t2, 0xbeef11dd, 14

    # ---------------- 4. 负偏移寻址 ----------------
    # 注意别写到 0x40c —— 那是上面 check 14 刚验证过的字，会被踩掉
    li   s1, 0x420
    li   t1, 0x5a5a5a5a
    sw   t1, -4(s1)          # 实际地址 0x41c
    li   s2, 0x41c
    lw   t2, 0(s2)
    CHECK t2, 0x5a5a5a5a, 15

    # ---------------- 5. 确认前面的数据没被踩坏 ----------------
    lw   t1, 0(s0)
    CHECK t1, 0x12345678, 16
    lw   t1, 12(s0)
    CHECK t1, 0xbeef11dd, 17

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
