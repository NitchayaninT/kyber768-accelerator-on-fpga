`timescale 1ns / 1ps
`define CLK_PERIOD 10

module sponge_controller_tb;

  localparam int MAX_RATE_BYTES = 168;

  logic clk;
  logic rst;
  logic start;
  logic block_in_ready;
  logic last_block;
  logic matrix_gen;
  logic busy;
  logic perm_done;
  logic [15:0] rate_bytes;
  logic [MAX_RATE_BYTES*8-1:0] block_in;
  logic [MAX_RATE_BYTES*8-1:0] block_out;
  logic block_out_valid;
  logic done;

  sponge_controller dut (
      .clk           (clk),
      .rst           (rst),
      .start         (start),
      .block_in_ready(block_in_ready),
      .last_block    (last_block),
      .matrix_gen    (matrix_gen),
      .busy          (busy),
      .perm_done     (perm_done),
      .rate_bytes    (rate_bytes),
      .block_in      (block_in),
      .block_out     (block_out),
      .block_out_valid(block_out_valid),
      .done          (done)
  );

  initial begin
    clk = 0;
    forever #(`CLK_PERIOD / 2) clk = ~clk;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, sponge_controller_tb);
  end

  // Print n bytes of block_out starting from byte 0 (matches C print_hex order)
  task print_out(input int n);
    for (int i = 0; i < n; i++)
      $write("%02h", block_out[8*i+:8]);
    $display("");
  endtask

  // Assert block_in_ready for one clock cycle
  task send_block(
    input logic [MAX_RATE_BYTES*8-1:0] blk,
    input logic is_last,
    input logic is_mgen
  );
    block_in       = blk;
    last_block     = is_last;
    matrix_gen     = is_mgen;
    block_in_ready = 1;
    @(posedge clk);
    block_in_ready = 0;
  endtask

  // Send a non-last block then wait for the sponge to return to SC_WAIT_BLOCK_IN
  task send_middle_block(input logic [MAX_RATE_BYTES*8-1:0] blk);
    send_block(blk, 1'b0, 1'b0);
    wait(perm_done);
    @(posedge clk);
  endtask

  task reset_dut();
    rst            = 1;
    start          = 0;
    block_in_ready = 0;
    last_block     = 0;
    matrix_gen     = 0;
    block_in       = '0;
    rate_bytes     = 16'd0;
    repeat(2) @(posedge clk);
    rst            = 0;
    repeat(2) @(posedge clk);
  endtask

  // Pulse start and wait until FSM reaches SC_WAIT_BLOCK_IN
  task start_sponge();
    start = 1;
    @(posedge clk);
    start = 0;
    @(posedge clk);  // SC_INIT -> SC_WAIT_BLOCK_IN
  endtask

  initial begin
    logic [MAX_RATE_BYTES*8-1:0] blk;

    reset_dut();

    // ----------------------------------------------------------------
    // Test 1: SHA3-256(32 zero bytes)
    // rate=136, suffix=0x06 at byte 32, 0x80 at byte 135 (rate-1)
    // ----------------------------------------------------------------
    $display("--- Test 1: SHA3-256(32 zero bytes) ---");
    rate_bytes = 16'd136;
    blk = '0;
    blk[32*8  +: 8] = 8'h06;
    blk[135*8 +: 8] = 8'h80;
    start_sponge();
    send_block(blk, 1'b1, 1'b0);
    wait(done); @(posedge clk);
    $write("out: "); print_out(32);
    $display("");
    reset_dut();

    // ----------------------------------------------------------------
    // Test 2: SHA3-512(32 zero bytes)
    // rate=72, suffix=0x06 at byte 32, 0x80 at byte 71 (rate-1)
    // ----------------------------------------------------------------
    $display("--- Test 2: SHA3-512(32 zero bytes) ---");
    rate_bytes = 16'd72;
    blk = '0;
    blk[32*8 +: 8] = 8'h06;
    blk[71*8 +: 8] = 8'h80;
    start_sponge();
    send_block(blk, 1'b1, 1'b0);
    wait(done); @(posedge clk);
    $write("out: "); print_out(64);
    $display("");
    reset_dut();

    // ----------------------------------------------------------------
    // Test 3: SHAKE128(32 zero bytes) — 1 squeeze block (168 bytes)
    // rate=168, suffix=0x1F at byte 32, 0x80 at byte 167 (rate-1)
    // ----------------------------------------------------------------
    $display("--- Test 3: SHAKE128(32 zero bytes, 1 block = 168 bytes) ---");
    rate_bytes = 16'd168;
    blk = '0;
    blk[32*8  +: 8] = 8'h1F;
    blk[167*8 +: 8] = 8'h80;
    start_sponge();
    send_block(blk, 1'b1, 1'b0);
    wait(done); @(posedge clk);
    $write("out: "); print_out(168);
    $display("");
    reset_dut();

    // ----------------------------------------------------------------
    // Test 4: SHAKE256(32 zero bytes) — 1 squeeze block (136 bytes)
    // rate=136, suffix=0x1F at byte 32, 0x80 at byte 135 (rate-1)
    // ----------------------------------------------------------------
    $display("--- Test 4: SHAKE256(32 zero bytes, 1 block = 136 bytes) ---");
    rate_bytes = 16'd136;
    blk = '0;
    blk[32*8  +: 8] = 8'h1F;
    blk[135*8 +: 8] = 8'h80;
    start_sponge();
    send_block(blk, 1'b1, 1'b0);
    wait(done); @(posedge clk);
    $write("out: "); print_out(136);
    $display("");
    reset_dut();

    // ----------------------------------------------------------------
    // Test 5: SHA3-256(zero PK = 1184 bytes)
    // KYBER_PUBLICKEYBYTES = 3*384 + 32 = 1184 bytes
    // 1184 / 136 = 8 full blocks + 96 bytes remainder
    // → 8 middle blocks (all zero) + 1 last block (suffix at byte 96)
    // ----------------------------------------------------------------
    $display("--- Test 5: SHA3-256(zero PK = 1184 bytes, 9 blocks) ---");
    rate_bytes = 16'd136;
    start_sponge();
    for (int b = 0; b < 8; b++)
      send_middle_block('0);
    blk = '0;
    blk[96*8  +: 8] = 8'h06;
    blk[135*8 +: 8] = 8'h80;
    send_block(blk, 1'b1, 1'b0);
    wait(done); @(posedge clk);
    $write("out: "); print_out(32);
    $display("");
    reset_dut();

    // ----------------------------------------------------------------
    // Test 6: SHA3-256(zero ct = 1088 bytes)
    // KYBER_CIPHERTEXTBYTES = 3*320 + 128 = 1088 bytes
    // 1088 / 136 = 8 exactly → 8 data blocks + 1 pure padding block
    // Last block: suffix at byte 0 (message ended on block boundary)
    // ----------------------------------------------------------------
    $display("--- Test 6: SHA3-256(zero ct = 1088 bytes, 9 blocks) ---");
    rate_bytes = 16'd136;
    start_sponge();
    for (int b = 0; b < 8; b++)
      send_middle_block('0);
    blk = '0;
    blk[0*8   +: 8] = 8'h06;
    blk[135*8 +: 8] = 8'h80;
    send_block(blk, 1'b1, 1'b0);
    wait(done); @(posedge clk);
    $write("out: "); print_out(32);
    $display("");
    reset_dut();

    // ----------------------------------------------------------------
    // Test 7: SHAKE128 matrix gen (seed=0, i=0, j=0) — 4 squeeze blocks
    // kyber_shake128_absorb pads seed||i||j = 34 bytes
    // matrix_gen=1 → 4 squeeze rounds of 168 bytes = 672 bytes total
    // squeeze[0] must match Test 3 out (same input, same first block)
    // ----------------------------------------------------------------
    $display("--- Test 7: SHAKE128 matrix gen (seed=0, i=0, j=0) ---");
    rate_bytes = 16'd168;
    blk = '0;
    blk[34*8  +: 8] = 8'h1F;
    blk[167*8 +: 8] = 8'h80;
    start_sponge();
    send_block(blk, 1'b1, 1'b1);
    repeat(4) begin
      wait(block_out_valid);
      @(posedge clk); #1;
      $write("squeeze: "); print_out(168);
    end
    wait(done); @(posedge clk);
    $display("");

    $display("all tests done");
    $finish;
  end

endmodule
