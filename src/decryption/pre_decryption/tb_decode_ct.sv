`timescale 1ns/1ps

module tb_decode_ct;

  logic clk = 0, rst = 1, enable = 0;
  always #5 clk = ~clk;

  logic [7:0]  c1 [0:959];
  logic [7:0]  c2 [0:127];
  logic [15:0] u  [0:2][0:255];
  logic [15:0] v  [0:255];
  logic        decompress_done;

  // temp memories for iverilog
  logic [7:0] c1_mem [0:959];
  logic [7:0] c2_mem [0:127];

  decode_ct dut (
    .enable(enable),
    .rst(rst),
    .clk(clk),
    .c1(c1),
    .c2(c2),
    .u(u),
    .v(v),
    .decompress_done(decompress_done)
  );

  int i;


  initial begin
      $monitor("T=%0t state=%0d poly=%0d blk=%0d done=%0b base=%0d u00=%h",
                $time,
                dut.state,
                dut.poly_i,
                dut.blk_j,
                decompress_done,
                dut.base,
                u[0][0]);
    // ---------------- LOAD INPUTS ----------------
    $readmemh("c1.mem", c1_mem);
    $readmemh("c2.mem", c2_mem);

    for (i = 0; i < 960; i++) c1[i] = c1_mem[i];
    for (i = 0; i < 128; i++) c2[i] = c2_mem[i];


    // ---------------- RESET ----------------
    rst = 1;
    repeat (3) @(posedge clk);
    rst = 0;

    // ---------------- START ----------------
    @(negedge clk);
    enable = 1;
    @(negedge clk);
    enable = 0;

    // ---------------- WAIT DONE ----------------
    wait (decompress_done);
    repeat (2) @(posedge clk);

    $display("\n============= DECOMPRESS DONE =============");


    $finish;
  end

endmodule
