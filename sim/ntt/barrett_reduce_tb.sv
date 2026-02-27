`timescale 1ns / 1ps
import params_pkg::*;
module barrett_reduce_tb;
  reg clk;
  reg start;
  reg signed [KYBER_POLY_WIDTH - 1:0] a;
  wire signed [KYBER_POLY_WIDTH - 1:0] r;
  barrett_reduce #() barett_reduce (
      .clk  (clk),
      .start(start),
      .a    (a),
      .r    (r)
  );

  initial begin
    forever begin
      #1 clk = ~clk;
    end
  end

  initial begin
    clk = 1;
    #10;
    start <= 1;
    a = 16'sh193d;
    #2 start <= 0;
    #10 $display("R(base10) %d, R(base16) %h", r, r);
    #10 a = 16'sh1111;
    start <= 1;
    #2 start <= 0;
    #20 $display("R(base10) %d, R(base16) %h", r, r);
    $finish;
  end
endmodule
