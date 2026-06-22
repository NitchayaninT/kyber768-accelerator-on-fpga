`timescale 1ns / 1ps
import params_pkg::*;

module decode_sk (
    input logic [(KYBER_N * KYBER_RQ_WIDTH * KYBER_K)-1:0] s,  // pre-k, coin
    output logic [(KYBER_N * KYBER_RQ_WIDTH)-1:0] s_t[0:2]  // decryption key s
);
  genvar i,j;
      generate
      for (i = 0; i < KYBER_K; i = i + 1) begin
        for (j = 0; j < KYBER_N; j = j + 1) begin
          assign s_t[i][KYBER_RQ_WIDTH*j +: KYBER_RQ_WIDTH] = s[(i*KYBER_N + j)*KYBER_RQ_WIDTH +: KYBER_RQ_WIDTH];
        end
      end
  endgenerate

endmodule
