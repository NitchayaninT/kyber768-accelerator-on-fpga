`timescale 1ns/1ps
module fqmul_tb;

  reg start;
  reg clk;
  reg signed [15:0] a, b;
  wire signed [15:0] r;

  fqmul dut (
    .clk(clk),
    .start(start),
    .a(a),
    .b(b),
    .r(r)
  );

  always #1 clk = ~clk;

  initial begin
    clk = 0;
    start = 0;
    a = 0;
    b = 0;
    #10;
    // test vector 1
    start = 1;
    a = 16'sd17;
    b = 16'sd23;
    #2;
    start = 0;
    #6;
    $display("r = %d", r);
    // test vector 2
    start = 1;
    a = -16'sd1044;
    b = 16'sd287;
    #2;
    start = 0;
    #6;
    $display("r = %d", r);
    #10;
    $finish;
  end
endmodule
