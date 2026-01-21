// HASH top module
// Workflow
// Seed 256 bits -> SHAKE128 -> 5376 bits public matrix A transpose -> Reject sampling -> 9 polynomials of degree 256 with coeffs in [0,3328]
// Coins 256 bits -> SHAKE128 -> 1024 bits noise -> CBD -> polynomial of degree 256 with coeffs in [-2,2]
`timescale 1ns / 1ps
module hash_top(
    input clk,
    input rst,
    input enable,
    input [255:0] coins,
    input [255:0] seed,
    output reg noise_done,
    output reg public_matrix_done,
    output reg [4095:0] public_matrix_poly_out,
    output reg [4095:0] noise_poly_out
);
    wire shake_noise_done;
    wire shake_public_matrix_done;
    wire [5375:0] noise_stream;
    wire [5375:0] public_matrix_stream;

    shake256 shake256_coin (
        .clk(clk),
        .enable(enable),
        .rst(rst),
        .in(coins),
        .domain(4'b1111), // domain separator for noise generation
        .output_len(14'd1024), // output length 1024 bits
        .output_string(noise_stream),
        .done(shake_noise_done)
    );

    shake128 shake128_public_matrix (
        .clk(clk),
        .enable(enable),
        .rst(rst),
        .in(seed),
        .domain(4'b1111), // domain separator for public matrix generation
        .output_len(14'd5376), // output length 5376 bits
        .output_string(public_matrix_stream),
        .done(shake_public_matrix_done)
    );

    cbd cbd_module (
        .clk(clk),
        .rst(rst),
        .enable(shake_noise_done),
        .noise(noise_stream),
        .done(noise_done),
        .poly_out(noise_poly_out)
    );

    reject_sampling reject_sampling_module (
        .clk(clk),
        .rst(rst),
        .enable(shake_public_matrix_done),
        .byte_stream(public_matrix_stream),
        .done(public_matrix_done),
        .public_matrix_poly(public_matrix_poly_out)
    );

endmodule