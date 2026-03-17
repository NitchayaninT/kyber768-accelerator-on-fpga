`timescale 1ns / 1ps
import params_pkg::*;

module basemul_tb;

  logic clk;
  logic start;
  logic reset;
  logic signed [KYBER_POLY_WIDTH - 1:0] a[2];
  logic signed [KYBER_POLY_WIDTH - 1:0] b[2];
  logic signed [KYBER_POLY_WIDTH - 1:0] zeta;
  logic signed [KYBER_POLY_WIDTH - 1:0] r[2];
  logic valid;

  basemul basemul_uut (
      .clk(clk),
      .reset(reset),
      .start(start),
      .a(a),
      .b(b),
      .zeta(zeta),
      .r(r),
      .valid(valid)
  );

  initial begin
    clk   <= 0;
    start <= 0;
    reset <= 0;
    a[0]  <= 0;
    a[1]  <= 0;
    b[0]  <= 0;
    b[1]  <= 0;
    zeta  <= 0;

    #2 reset <= 1;
    #2 reset <= 0;

    #2 start <= 1;
    a[0] <= 1675;
    a[1] <= 1057;
    b[0] <= 3110;
    b[1] <= 1746;
    zeta <= 1628;

    #2 start <= 0;

    #40 start <= 1;
    a[0] <= 2983;
    a[1] <= 1509;
    b[0] <= 1897;
    b[1] <= 497;
    zeta <= -zeta;

    #50 $finish;
  end

  always @(posedge basemul_uut.valid) begin
    $display("a = %d%d, b = %d%d\nr = %d%d\n", a[1], a[0], b[1], b[0], r[1], r[0]);
  end
  initial begin
    forever begin
      #1 clk = ~clk;
    end
  end
endmodule
