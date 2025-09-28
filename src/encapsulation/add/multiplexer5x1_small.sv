// this module is combinational circuit
// main purpose to feed correct input to cla_adder module
`timescale 1ns / 1ps
`include "params.vh"

// This is variation of mutiplexer that can recieve small polynomials
// except in4 will be normal polynomial

// KYBER_N = 256
// KYBER_SPOLY_WIDTH = 3
// KYBER_COEf_WIDTH = 12
module multiplexer5x1_small (
    input [2:0] selector,
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) - 1 : 0] in0, // e_2
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) - 1 : 0] in1, // e_1[0]
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) - 1 : 0] in2, // e_1[1]
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) - 1 : 0] in3, // e_1[2]
    input [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] in4,  // msg_poly
    output reg [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] out
);

  logic [`KYBER_SPOLY_WIDTH-1:0] coeff;
  integer i;
  always_comb begin
    if (selector == 4) begin
      out = in4;  // pass-through full polynomial
    end else begin
      for (i = 0; i < `KYBER_N; i = i + 1) begin
        logic [`KYBER_SPOLY_WIDTH-1:0] coeff;
        case (selector)
          0: coeff = in0[i*`KYBER_SPOLY_WIDTH+:`KYBER_SPOLY_WIDTH];
          1: coeff = in1[i*`KYBER_SPOLY_WIDTH+:`KYBER_SPOLY_WIDTH];
          2: coeff = in2[i*`KYBER_SPOLY_WIDTH+:`KYBER_SPOLY_WIDTH];
          3: coeff = in3[i*`KYBER_SPOLY_WIDTH+:`KYBER_SPOLY_WIDTH];
          default: coeff = 'x;
        endcase

        // Expand small coefficient to 12-bit
        out[i*`KYBER_R_WIDTH +: `KYBER_R_WIDTH] =
        (coeff == 3'b111) ? `KYBER_Q-1 : //3328
        (coeff == 3'b110) ? `KYBER_Q-2 : //3327
        coeff; // 0,1,2
      end
    end
  end
endmodule
