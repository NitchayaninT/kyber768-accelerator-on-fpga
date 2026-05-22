`timescale 1ns / 1ps
import params_pkg::*;
module pre_decryption #(
    parameter SK_WIDTH = (KYBER_N * KYBER_POLY_WIDTH * KYBER_K)  //secretkey
    + (KYBER_N) + (KYBER_K * KYBER_RQ_WIDTH * KYBER_N)  //public key(PK)
    + (2 * KYBER_N)
)  //pre_k & coin
(
    input logic clk,
    input logic start,
    input logic rst,
    output logic [7:0] c1[0:959],
    output logic [7:0] c2[0:127],
    input logic [SK_WIDTH-1:0] sk,
    output logic [(KYBER_N * KYBER_RQ_WIDTH)-1:0] u[0:2],
    output logic [(KYBER_N * KYBER_RQ_WIDTH)-1:0] v,
    output logic [(KYBER_N * KYBER_POLY_WIDTH)-1:0] s_T[0:2]
);
  logic [KYBER_N * KYBER_POLY_WIDTH * KYBER_K-1:0] s = sk[0:(KYBER_N*KYBER_POLY_WIDTH*KYBER_K)-1];


endmodule

