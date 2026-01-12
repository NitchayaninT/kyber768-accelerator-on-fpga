// HASH top module
// Workflow
// Coins 256 bits -> SHAKE128 -> 1024 bits noise -> CBD -> polynomial of degree 256 with coeffs in [-2,2]
`timescale 1ns / 1ps
module hash_top(
    input clk,
    input rst,
    input enable,
    input [255:0] coins,
    output reg done,
    output reg [1023:0] poly_out
);
    wire shake_done;
    wire [5375:0] shake_stream;

    shake128 shake128_module (
        .clk(clk),
        .enable(enable),
        .rst(rst),
        .in(coins),
        .domain(4'b1111), // domain separator for noise generation
        .output_len(14'd1024), // output length 1024 bits
        .output_string(shake_stream),
        .done(shake_done) // not used here
    );

    cbd cbd_module (
        .clk(clk),
        .rst(rst),
        .enable(shake_done),
        .noise(shake_stream[1023:0]),
        .done(done),
        .poly_out(poly_out)
    );

endmodule