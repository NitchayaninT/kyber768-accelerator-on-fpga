// this module is combinational circuit
// main purpose to feed correct input to cla_adder module

`timescale 1ns / 1ps
`include "params.vh"

module multiplexer5x1 (
    input [2:0] selector,
    input [(`KYBER_N * 12) - 1 : 0] in0,
    input [(`KYBER_N * 12) - 1 : 0] in1,
    input [(`KYBER_N * 12) - 1 : 0] in2,
    input [(`KYBER_N * 12) - 1 : 0] in3,
    input [(`KYBER_N * 12) - 1 : 0] in4,
    output reg [(`KYBER_N * 12) - 1 : 0] out
);

  always_comb begin
    case (selector)
      0: out = in0;
      1: out = in1;
      2: out = in2;
      3: out = in3;
      4: out = in4;
      default: out = 'x;
    endcase
  end
endmodule
