// ============================================================
// rv32i_core.sv —— Lab 0：RV32I 单周期处理器
//
// ★ 这个文件是你的作业。目前是一个空壳（所有输出恒 0），
//   第一次跑 `make sim` 一定是 TIMEOUT —— 那就是对的起点。
//   填完之后 `make test` 应该 5 个程序全 PASS。
//
// 参考：Patterson & Hennessy《Computer Organization and Design》
//       RISC-V 版 Ch.4 "The Processor" —— 按书上的图直接翻译成 RTL 即可
//
// ------------------------------------------------------------
// 单周期 = 一条指令在一个时钟周期内走完下面 5 段。
// 注意：这 5 段在单周期里是「一条很长的组合逻辑链」，不是 5 级流水线，
//       中间没有流水线寄存器。等你做 Lab 1a 才把它们切开。
//
//              ┌────┐   ┌────┐   ┌────┐   ┌─────┐   ┌────┐
//        PC ──>│ IF │──>│ ID │──>│ EX │──>│ MEM │──>│ WB │
//              └────┘   └────┘   └────┘   └─────┘   └────┘
//                │        │        │        │          │
//          imem_addr    译码      ALU    dmem 读写   写回 regfile
//                     regfile 读
//
// ------------------------------------------------------------
// 实现清单（建议按这个顺序做，每做完一项就跑一次 make sim 看进展）：
//
//   [ ] 1. PC 寄存器：复位到 RESET_PC，每拍 PC <= next_pc
//   [ ] 2. 译码器：opcode / funct3 / funct7 -> 各控制信号
//   [ ] 3. 立即数生成器：I / S / B / U / J 五种格式
//   [ ] 4. 寄存器堆：2 读 1 写；x0 恒为 0（写 x0 要丢弃）
//   [ ] 5. ALU：add sub and or xor sll srl sra slt sltu
//   [ ] 6. next-PC 逻辑：PC+4 / 分支 / jal / jalr
//   [ ] 7. load/store：字节使能 dmem_wstrb；load 结果做符号/零扩展
//   [ ] 8. 写回 MUX：ALU 结果 / dmem_rdata / PC+4
//
// ------------------------------------------------------------
// 两条「单周期」的硬性约定，和 tb 对齐好：
//   - imem/dmem 都是组合读：地址给出，当拍数据就回来
//   - dmem 是同步写：在时钟上升沿按 dmem_wstrb 逐字节写入
//     （dmem_wstrb 没置位的那几个字节必须保持不变 —— 这是 t03 的重点）
// ============================================================

module rv32i_core #(
    parameter logic [31:0] RESET_PC = 32'h0000_0000
) (
    input  logic        clk,
    input  logic        rst_n,

    // 指令存储器：组合读
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    // 数据存储器：组合读、同步写
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic [ 3:0] dmem_wstrb,
    output logic        dmem_we,
    input  logic [31:0] dmem_rdata
);

    // ============================================================
    // TODO: 从这里开始写你的实现
    // ============================================================
    assign imem_addr  = RESET_PC;
    assign dmem_addr  = 32'h0;
    assign dmem_wdata = 32'h0;
    assign dmem_wstrb = 4'h0;
    assign dmem_we    = 1'b0;

endmodule
