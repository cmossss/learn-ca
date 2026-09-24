// ============================================================
// tb_top.sv —— Lab 0 通用测试平台
//
//  职责：
//    1. 产生时钟 / 复位
//    2. 把 sw/*.S 汇编出来的 .hex 装进指令存储器
//    3. 提供指令存储器 + 数据存储器模型（组合读、同步写）
//    4. 监视两个「魔法地址」：
//         0x100  RESULT —— 打印结果，不结束
//         0x200  TOHOST —— 写 1 => PASS 并结束
//                          写 (check<<1)|1 => FAIL 并报出是哪条 CHECK
//                          ^ 这就是 riscv-tests 的标准 tohost 约定，
//                            以后你跑官方测试套件时是同一套机制
//    5. 超时保护（RTL 有 bug 时不会挂死）
//
//  运行：
//    sim +prog=<hex 文件> [+wave=<fst 文件>] [+trace]
//      +prog   必填，要加载的程序
//      +wave   可选，dump 波形到这个文件
//      +trace  可选，把前 400 条指令逐条打印出来
//
//  注意：这是给「单周期」CPU 用的。imem/dmem 都是组合读 —— 给出地址，
//        当拍数据就回来。等你写 Lab 1 的流水线版本时，这个 tb 需要改：
//        要么给存储器加一拍延迟，要么把 CPU 内部的流水线寄存器暴露出来。
// ============================================================

`timescale 1ns/1ps

module tb_top;

  // ---------------- 与 sw/*.S 的约定 ----------------
  localparam logic [31:0] RESULT_ADDR = 32'h0000_0100;
  localparam logic [31:0] TOHOST_ADDR = 32'h0000_0200;

  // ---------------- 存储器尺寸 ----------------
  localparam int IMEM_WORDS = 4096;                    // 16 KiB
  localparam int DMEM_WORDS = 4096;                    // 16 KiB
  localparam int IMEM_AW    = $clog2(IMEM_WORDS);      // 字地址位宽 = 12
  localparam int DMEM_AW    = $clog2(DMEM_WORDS);

  localparam int TIMEOUT_CYC = 200_000;
  localparam int TRACE_MAX   = 400;

  // ---------------- 时钟 / 复位 ----------------
  logic clk   = 1'b0;
  logic rst_n = 1'b0;

  always #5 clk = ~clk;                                // 周期 10ns

  // ---------------- DUT 端口 ----------------
  logic [31:0] imem_addr, imem_rdata;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
  logic [ 3:0] dmem_wstrb;
  logic        dmem_we;

  // ---------------- 存储器模型 ----------------
  logic [31:0] imem [0:IMEM_WORDS-1];
  logic [31:0] dmem [0:DMEM_WORDS-1];

  // 组合读：地址进来，数据当拍出去
  assign imem_rdata = imem[imem_addr[IMEM_AW+1:2]];
  assign dmem_rdata = dmem[dmem_addr[DMEM_AW+1:2]];

  // 字节使能 -> 写掩码
  logic [31:0] dmem_wmask;
  always_comb
    for (int b = 0; b < 4; b++)
      dmem_wmask[b*8 +: 8] = {8{dmem_wstrb[b]}};

  // 同步写
  always @(posedge clk) begin
    if (rst_n && dmem_we)
      dmem[dmem_addr[DMEM_AW+1:2]] <= (dmem[dmem_addr[DMEM_AW+1:2]] & ~dmem_wmask)
                                    | (dmem_wdata & dmem_wmask);
  end

  // ---------------- 魔法地址监视 ----------------
  always @(posedge clk) begin
    if (rst_n && dmem_we) begin
      if (dmem_addr == RESULT_ADDR) begin
        $display("[%0t] RESULT = %0d  (0x%08x)", $time, $signed(dmem_wdata), dmem_wdata);
      end
      if (dmem_addr == TOHOST_ADDR) begin
        if (dmem_wdata == 32'd1) begin
          $display("=== PASS ===");
        end else begin
          // riscv-tests 约定：tohost = (check << 1) | 1
          $display("=== FAIL === 第 %0d 条 CHECK 挂了", dmem_wdata >> 1);
        end
        $finish;
      end
    end
  end

  // ---------------- 周期计数 / 指令跟踪 / 超时 ----------------
  int unsigned cyc     = 0;
  int unsigned trace_n = 0;
  bit          trace_en = 1'b0;

  always @(posedge clk) begin
    if (rst_n) begin
      cyc <= cyc + 1;

      if (trace_en && trace_n < TRACE_MAX) begin
        $display("  [cyc %5d]  PC=%08x  instr=%08x", cyc, imem_addr, imem_rdata);
        trace_n <= trace_n + 1;
      end

      if (cyc >= TIMEOUT_CYC) begin
        $display("=== TIMEOUT === 跑了 %0d 拍没等到 tohost 写入", TIMEOUT_CYC);
        $display("  最后 PC=%08x  instr=%08x", imem_addr, imem_rdata);
        $display("  常见原因：PC 没在推进 / 卡在死循环 / 没实现 tohost 那两条 sw");
        $finish;
      end
    end
  end

  // ---------------- 初始化 ----------------
  string prog_file;
  string wave_file;

  initial begin
    if (!$value$plusargs("prog=%s", prog_file)) begin
      $display("ERROR: 缺少 +prog=<hex 文件>，例如 +prog=build/t02_fib.hex");
      $fatal;
    end
    trace_en = $test$plusargs("trace");

    // 先清零，再加载 —— 程序没用到的位置就是「全 0 指令」，
    // PC 万一跑飞了取到的是非法指令，比取到 X 好调试得多
    for (int i = 0; i < IMEM_WORDS; i++) imem[i] = 32'h0;
    for (int i = 0; i < DMEM_WORDS; i++) dmem[i] = 32'h0;
    $readmemh(prog_file, imem);

    $display("============================================================");
    $display(" Lab 0 testbench   prog = %s", prog_file);
    $display("============================================================");

`ifdef TRACE
    if ($value$plusargs("wave=%s", wave_file)) begin
      $dumpfile(wave_file);
      $dumpvars(0, tb_top);
      $display(" 波形 -> %s", wave_file);
    end
`endif

    // 复位
    rst_n = 1'b0;
    repeat (4) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  end

  // ---------------- DUT ----------------
  rv32i_core u_dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .imem_addr  (imem_addr),
    .imem_rdata (imem_rdata),
    .dmem_addr  (dmem_addr),
    .dmem_wdata (dmem_wdata),
    .dmem_wstrb (dmem_wstrb),
    .dmem_we    (dmem_we),
    .dmem_rdata (dmem_rdata)
  );

endmodule
