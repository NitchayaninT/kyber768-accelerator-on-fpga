`timescale 1ns / 1ps
module fqmul_tb;

  reg enable;
  reg clk;
  reg signed [15:0] a, b;
  wire signed [15:0] r;

  fqmul dut (
      .clk(clk),
      .enable(enable),
      .a(a),
      .b(b),
      .r(r)
  );

  always #1 clk = ~clk;

  initial begin
    clk = 0;
    enable = 0;
    a = 0;
    b = 0;
    #10;
    // test vector 1
    enable = 1;
    a = 16'sd17;
    b = 16'sd23;
    #2;
    enable = 0;
    #6;
    $display("r = %d", r);
    // test vector 2
    enable = 1;
    a = -16'sd1044;
    b = 16'sd287;
    #2;
    enable = 0;
    #6;
    $display("r = %d", r);
    #10;
    $finish;
  end
endmodule
