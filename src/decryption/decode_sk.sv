`timescale 1ns / 1ps
`include "params.vh"

  // KYBER_R_WIDTH = 12
  // KYBER_SPOLY_WIDTH  = 3
  // KYBER_N = 256
module decode_sk (
    input [(`KYBER_N * `KYBER_R_WIDTH * `KYBER_K) //decryption key s
      + 256 + (`KYBER_N * `KYBER_R_WIDTH * `KYBER_K)// encapsulation key
      +(2*`KYBER_N)- 1 : 0] in,  // pre-k, coin
    output wire [(`KYBER_N * `KYBER_R_WIDTH)-1:0] out[0:2]  // decryption key s
);

  localparam integer offset = 9984;
  genvar i;
  generate
    for (i = 0; i < 256; i = i + 1) begin : g_decode_sk
      assign out[0][i*`KYBER_R_WIDTH+:`KYBER_R_WIDTH] =
        in[offset+ i *`KYBER_R_WIDTH+:`KYBER_R_WIDTH];
      assign out[1][i*`KYBER_R_WIDTH+:`KYBER_R_WIDTH] =
        in[offset + (`KYBER_N*`KYBER_R_WIDTH) + i * `KYBER_R_WIDTH+:`KYBER_R_WIDTH];
      assign out[2][i*`KYBER_R_WIDTH+:`KYBER_R_WIDTH] =
        in[offset + 2*(`KYBER_N*`KYBER_R_WIDTH) + i* `KYBER_R_WIDTH+:`KYBER_R_WIDTH];
    end
  endgenerate
endmodule
