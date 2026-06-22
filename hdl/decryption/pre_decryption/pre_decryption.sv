`timescale 1ns / 1ps
import params_pkg::*;

module pre_decryption #(
    parameter SK_WIDTH = (KYBER_N *  KYBER_RQ_WIDTH * KYBER_K) + //s
                         (KYBER_N * KYBER_RQ_WIDTH * KYBER_K) + KYBER_N + // pk
                         (2 * KYBER_N)//pre_k + coin
)(
    input  logic [8703:0] ct,
    input  logic [SK_WIDTH-1:0] sk,

    output logic [7:0] c1 [0:959],
    output logic [7:0] c2 [0:127],
    output logic [(KYBER_N * KYBER_RQ_WIDTH * KYBER_K)-1:0] s, 
    output logic [(KYBER_N * KYBER_RQ_WIDTH * KYBER_K)+KYBER_N-1:0] PK, //(256 = rho) + t
    output logic [KYBER_N-1:0] pre_k,
    output logic [KYBER_N-1:0] coin
);

    integer i;
    //convert the flat ct into c1 and c2 element
    always_comb begin
        for (i = 0; i < 960; i = i + 1)
            c1[i] = ct[8*i +: 8];

        for (i = 0; i < 128; i = i + 1)
            c2[i] = ct[8*(960+i) +: 8];
    //  s = sk[]
        s     = sk[(KYBER_N * KYBER_RQ_WIDTH * KYBER_K)-1 : 0];

        PK    = sk[(KYBER_N * KYBER_RQ_WIDTH * KYBER_K) +
                   (KYBER_N * KYBER_RQ_WIDTH * KYBER_K) + KYBER_N +  - 1
                   :
                   (KYBER_N * KYBER_RQ_WIDTH * KYBER_K)];

        pre_k = sk[(KYBER_N * KYBER_RQ_WIDTH * KYBER_K) +
                   (KYBER_N * KYBER_RQ_WIDTH * KYBER_K) + KYBER_N +
                   KYBER_N - 1
                   :
                   (KYBER_N * KYBER_RQ_WIDTH * KYBER_K) +
                   (KYBER_N * KYBER_RQ_WIDTH * KYBER_K) + KYBER_N];

        coin  = sk[(KYBER_N * KYBER_RQ_WIDTH * KYBER_K) +
                   (KYBER_N * KYBER_RQ_WIDTH * KYBER_K) + KYBER_N +
                   (2*KYBER_N)  - 1
                   :
                   (KYBER_N * KYBER_RQ_WIDTH * KYBER_K) +
                   (KYBER_N * KYBER_RQ_WIDTH * KYBER_K) + KYBER_N +
                   KYBER_N];
    end

endmodule