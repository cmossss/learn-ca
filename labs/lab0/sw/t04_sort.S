# ============================================================
# t04_sort.S —— 综合：冒泡排序
#
# 验证范围：嵌套循环 + 分支 + load/store 全部串起来（Lab 0 的收官测试）
# 期望输出：=== PASS ===
#
# 数据来源：程序自己用一个 xorshift32 伪随机数发生器生成 16 个数写进内存。
#   为什么不直接写个常量数组？因为 Lab 0 的 CPU 是 Harvard 结构，
#   常量数组若放在 .text 里是取不到的（lw 读的是 dmem）。详见 sw/link.ld。
#
# 自检方式（不需要预先知道排序结果）：
#   3a. 排完之后必须非递减
#   3b. 元素总和前后一致（防止漏元素 / 重复元素）
# ============================================================

    .text
    .globl _start

    .equ RESULT_ADDR, 0x100
    .equ TOHOST_ADDR, 0x200
    .equ ARR, 0x400          # 数组基址
    .equ N,   16             # 元素个数

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
    li   s0, ARR             # 数组基址
    li   s1, N               # n

    # ---------------- 1. 生成数据并顺便求「排序前的和」----------------
    li   t0, 0               # i
    li   t1, 1               # xorshift32 状态，初值非 0
    li   s7, 0               # sum_before

gen_loop:
    bge  t0, s1, gen_done
    # xorshift32: x ^= x<<13; x ^= x>>17; x ^= x<<5
    slli t2, t1, 13
    xor  t1, t1, t2
    srli t2, t1, 17
    xor  t1, t1, t2
    slli t2, t1, 5
    xor  t1, t1, t2

    slli t2, t0, 2
    add  t2, s0, t2          # &arr[i]
    sw   t1, 0(t2)
    add  s7, s7, t1          # sum_before += arr[i]

    addi t0, t0, 1
    j    gen_loop
gen_done:

    # ---------------- 2. 冒泡排序 ----------------
    addi s1, s1, -1          # 轮数上限 = n-1
    li   s2, 0               # pass 计数
outer_loop:
    bge  s2, s1, sort_done
    sub  s4, s1, s2          # 本轮比较次数 = n-1-pass
    li   s5, 0               # j
inner_loop:
    bge  s5, s4, inner_done
    slli t0, s5, 2
    add  t0, s0, t0          # &arr[j]
    lw   t1, 0(t0)
    lw   t2, 4(t0)
    ble  t1, t2, no_swap     # arr[j] <= arr[j+1] 就不换
    sw   t2, 0(t0)
    sw   t1, 4(t0)
no_swap:
    addi s5, s5, 1
    j    inner_loop
inner_done:
    addi s2, s2, 1
    j    outer_loop
sort_done:
    addi s1, s1, 1           # s1 恢复成 n

    # ---------------- 3a. 校验：非递减 ----------------
    li   s5, 0
    addi s4, s1, -1          # 比较 n-1 次
vs_loop:
    bge  s5, s4, vs_done
    slli t0, s5, 2
    add  t0, s0, t0
    lw   t1, 0(t0)
    lw   t2, 4(t0)
    li   t6, 1
    bgt  t1, t2, fail        # arr[j] > arr[j+1] -> 没排好
    addi s5, s5, 1
    j    vs_loop
vs_done:

    # ---------------- 3b. 校验：元素总和不变 ----------------
    li   s5, 0
    li   s6, 0               # sum_after
sum_loop:
    bge  s5, s1, sum_done
    slli t0, s5, 2
    add  t0, s0, t0
    lw   t1, 0(t0)
    add  s6, s6, t1
    addi s5, s5, 1
    j    sum_loop
sum_done:
    CHECK_REG s6, s7, 2      # 加法在 2^32 下天然回绕，是置换的话两边必然相等

    # 3a 其实已经能抓住「排序没真的发生」——生成的随机序列本来就不是
    # 有序的，如果 store 通路坏了，数组保持原样，非递减检查必然失败。

    li   a0, 1               # a0 = 1 表示排序完成
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
