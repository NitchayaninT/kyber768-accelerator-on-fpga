// **************************************************
// butterfly module has 2 modes
// 1. cooley tukey butterfly : for NTT
// 2. gentleman sande butterfly : for INV_NTT
// note: barrett reduce step are done outside this module
// **************************************************
`timescale 1ns/1ps
import params_pkg::*;
import enums_pkg::*;

module butterfly_tb ();
  logic clk, enable;
  ntt_mode_e mode;
  logic valid;

  logic signed [KYBER_POLY_WIDTH - 1:0] a;
  logic signed [KYBER_POLY_WIDTH - 1:0] b;
  logic signed [KYBER_POLY_WIDTH - 1:0] zeta;  // can be both zeta and zeta inverse
  logic signed [KYBER_POLY_WIDTH - 1:0] out0;
  logic signed [KYBER_POLY_WIDTH - 1:0] out1;

  butterfly #() dut (
      .clk   (clk),
      .enable(enable),
      .mode  (mode),
      .a     (a),
      .b     (b),
      .zeta  (zeta),
      .out0  (out0),
      .out1  (out1),
      .valid (valid)
  );

  function [KYBER_POLY_WIDTH - 1:0] modq(input logic signed [KYBER_POLY_WIDTH - 1:0] a);
    return (((a % 3329) + 3329) %3329);
  endfunction
  always #1clk <= ~clk;
  initial begin
    clk <= 0;
    enable <=0;
    mode = NTT;
    a <= 3328;
    b <= 556;
    zeta <= 2226;

    #6 enable <= 1;
    #2 enable <= 0;

    wait(valid) begin
      $display("out0 = %d, out1 = %d\n", modq(out0), modq(out1));
    end

    #10 mode <= INV_NTT;
    #2 enable <= 1;
    #2 enable <= 0;

    wait(valid) begin
      $display("out0 = %d, out1 = %d\n", modq(out0), modq(out1));
    end
    #10
    $finish;

  end
endmodule
