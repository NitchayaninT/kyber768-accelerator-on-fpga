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
  logic [1:0] hash_mode;
  logic [MAX_RATE_BYTES*8-1:0] block_in;
  logic [MAX_RATE_BYTES*8-1:0] block_out;
  logic block_out_valid;
  logic done;

  sponge_controller dut (
      .clk          (clk),
      .rst          (rst),
      .start        (start),
      .block_in_ready(block_in_ready),
      .last_block   (last_block),
      .matrix_gen   (matrix_gen),
      .busy         (busy),
      .hash_mode    (hash_mode),
      .block_in     (block_in),
      .block_out    (block_out),
      .block_out_valid(block_out_valid),
      .done         (done)
  );

  initial begin
    clk = 0;
    forever #(`CLK_PERIOD / 2) clk = ~clk;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, sponge_controller_tb);
  end

  // Task: send one block and wait for done
  task send_block(
    input logic [MAX_RATE_BYTES*8-1:0] blk,
    input logic is_last,
    input logic is_matrix_gen
  );
    block_in       = blk;
    last_block     = is_last;
    matrix_gen     = is_matrix_gen;
    block_in_ready = 1;
    @(posedge clk);
    block_in_ready = 0;
  endtask

  task reset_dut();
    rst            = 1;
    start          = 0;
    block_in_ready = 0;
    last_block     = 0;
    matrix_gen     = 0;
    block_in       = '0;
    repeat(2) @(posedge clk);
    rst = 0;
    repeat(2) @(posedge clk);
  endtask

  // --------------------------------------------------------
  // Test 1: SHA3-256 of empty string (single block)
  // Pre-padded block: byte[0]=0x06, byte[135]=0x80, rest 0
  // Expected: a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a
  // --------------------------------------------------------
  initial begin
    logic [MAX_RATE_BYTES*8-1:0] padded_block;

    reset_dut();

    $display("-- Test 1: SHA3-256 empty string --");
    hash_mode    = 2'b00;
    padded_block = '0;
    padded_block[7:0]         = 8'h06;  // domain suffix
    padded_block[135*8+7:135*8] = 8'h80;  // multi-rate padding

    start = 1;
    @(posedge clk);
    start = 0;

    @(posedge clk);  // wait for SC_WAIT_BLOCK_IN
    send_block(padded_block, 1'b1, 1'b0);

    wait(done);
    @(posedge clk);
    $display("block_out[255:0] = %h", block_out[255:0]);
    $display("expected         = a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a");

    // --------------------------------------------------------
    // Test 2: SHAKE128 matrix gen (single block, 3 squeezes)
    // block_in = arbitrary seed data, matrix_gen=1
    // --------------------------------------------------------
    repeat(4) @(posedge clk);
    reset_dut();

    $display("-- Test 2: SHAKE128 matrix gen (3 squeezes) --");
    hash_mode    = 2'b10;
    padded_block = '0;
    padded_block[7:0]           = 8'h1F;   // SHAKE128 domain suffix
    padded_block[167*8+7:167*8] = 8'h80;   // multi-rate padding at byte 167

    start = 1;
    @(posedge clk);
    start = 0;

    @(posedge clk);
    send_block(padded_block, 1'b1, 1'b1);

    // Capture each squeeze output.
    // block_out is updated via NBA in the same cycle block_out_valid fires,
    // so wait one posedge then #1 to let NBAs settle before sampling.
    repeat(3) begin
      wait(block_out_valid);
      @(posedge clk);
      #1;
      $display("squeeze block_out = %h", block_out[255:0]);
    end

    wait(done);
    @(posedge clk);
    $display("matrix gen done");

    $finish;
  end

endmodule
