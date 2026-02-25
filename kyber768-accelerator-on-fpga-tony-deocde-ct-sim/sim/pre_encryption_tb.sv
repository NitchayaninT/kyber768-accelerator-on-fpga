`timescale 1ns / 1ps
`include "params.vh"

module pre_encryption (
    input clk,
    input start,
    input rst,
    reg [`KYBER_N - 1:0] r_in,
    reg [(`KYBER_K * `KYBER_RQ_WIDTH * `KYBER_N)-1:0] encryption_key,
    wire [(`KYBER_N * `KYBER_POLY_WIDTH)-1:0] e2, //flattern
    wire [(`KYBER_N * `KYBER_POLY_WIDTH * `KYBER_K)-1:0] e1, //flattern
    wire [(`KYBER_N * `KYBER_POLY_WIDTH * `KYBER_K)-1:0] r, //flattern
    wire [(`KYBER_N * `KYBER_POLY_WIDTH * `KYBER_K)-1:0] t_trans, //flattern
    wire [(`KYBER_POLY_WIDTH * `KYBER_N * `KYBER_K * `KYBER_K) - 1 : 0] a_t,
    wire [`KYBER_RQ_WIDTH * `KYBER_K - 1 : 0] msg_poly,
    wire valid

);
    // Instantiate noise gen module
    wire noise_done;
    noise_gen noise_gen_uut (
        .clk(clk),
        .rst(rst),
        .enable(start),
        .coin(r_in),
        .noise_done(noise_done),
        .r(r),
        .e1(e1),
        .e2(e2)
    );
    
    // Instantiate public matrix module
    wire public_matrix_done;
    public_matrix public_matrix_uut (
        .clk(clk),
        .rst(rst),
        .enable(start),
        .encryption_key(encryption_key),
        .done(public_matrix_done),
        .a_t(a
endmodule