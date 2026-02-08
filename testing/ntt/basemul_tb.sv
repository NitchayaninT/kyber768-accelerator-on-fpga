`timescale 1ns / 1ps
`include "params.vh"

module basemul_tb;

  reg clk;
  reg start;
  reg signed [`KYBER_POLY_WIDTH - 1:0] a[2];
  reg signed [`KYBER_POLY_WIDTH - 1:0] b[2];
  reg signed [`KYBER_POLY_WIDTH - 1:0] zeta;
  wire signed [`KYBER_POLY_WIDTH - 1:0] r[2];
  wire vaild;

  basemul basemul_uut (
      .clk(clk),
      .basemul_start(start),
      .a(a),
      .b(b),
      .zeta(zeta),
      .r(r),
      .valid(vaild)
  );

  initial begin
    clk   <= 0;
    start <= 0;
    a[0]  <= 0;
    a[1]  <= 0;
    b[0]  <= 0;
    b[1]  <= 0;
    zeta  <= 0;

    #2 start <= 1;
    a[0] <= -24545;
    a[1] <= 17417;
    b[0] <= -14255;
    b[1] <= -18561;
    zeta = 2226;

    #2 start <= 0;
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
