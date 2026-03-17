`timescale 1ns / 1ps
import params_pkg::*;

module decode_sk (
    input logic [(KYBER_N * KYBER_POLY_WIDTH * KYBER_K)-1:0] s,  // pre-k, coin
    output logic [(KYBER_N * KYBER_POLY_WIDTH)-1:0] s_t[0:2]  // decryption key s
);
  integer i;
  integer j;
  for (i = 0; i < KYBER_K; i = i + 1) begin
    for (j = 0; j < KYBER_N; j = j + 1) begin
      assign s_t[i][j] = s[i*KYBER_N+j];
    end
  end

endmodule
