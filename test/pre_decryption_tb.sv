`timescale 1ns/1ps
import params_pkg::*;

module tb_pre_decryption;

    localparam SK_WIDTH = (KYBER_N * KYBER_RQ_WIDTH * KYBER_K) +
                          (KYBER_N * KYBER_RQ_WIDTH * KYBER_K) + KYBER_N +
                          (2 * KYBER_N);

    logic [8703:0] ct;
    logic [SK_WIDTH-1:0] sk;

    logic [7:0] c1 [0:959];
    logic [7:0] c2 [0:127];
    logic [(KYBER_N * KYBER_RQ_WIDTH * KYBER_K)-1:0] s;
    logic [(KYBER_N * KYBER_RQ_WIDTH * KYBER_K)+KYBER_N-1:0] PK;
    logic [KYBER_N-1:0] pre_k;
    logic [KYBER_N-1:0] coin;

    reg [7:0] ct_mem [0:1087];
    reg [7:0] sk_mem [0:2399];

    pre_decryption dut (
        .ct(ct),
        .sk(sk),
        .c1(c1),
        .c2(c2),
        .s(s),
        .PK(PK),
        .pre_k(pre_k),
        .coin(coin)
    );
    generate
        genvar i,j;
        for (i = 0; i < 1088; i = i + 1)
                assign ct[8*i +: 8] = ct_mem[i];
        for (j = 0; j < 2400; j = j + 1)
                assign sk[8*j +: 8] = sk_mem[j];
    endgenerate
    initial begin
        $readmemh("C:/Users/USER-HP-PRO-2022-016/kyber768-accelerator-on-fpga/hdl/decryption/pre_decryption/ct.txt", ct_mem);
        $readmemh("C:/Users/USER-HP-PRO-2022-016/kyber768-accelerator-on-fpga/hdl/decryption/pre_decryption/sk.txt", sk_mem);
        #10;
        $display("Test finished");
        $finish;
    end

endmodule