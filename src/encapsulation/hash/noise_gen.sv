`timescale 1ns / 1ps
module noise_gen(
    input clk,
    input rst,
    input enable,
    //input [255:0] coins,
    input [255:0] seed,
    //output reg noise_done,
    output reg public_matrix_done,
    // output 1 poly at a time
    output reg [3:0] public_matrix_poly_index,
    output reg public_matrix_poly_valid,
    output reg [4095:0] public_matrix_poly_out
    //output reg [4095:0] noise_poly_out
);
// -- Noise gen -- //
    wire shake_noise_done;
    wire [5375:0] noise_stream;

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

    cbd cbd_module (
        .clk(clk),
        .rst(rst),
        .enable(shake_noise_done),
        .noise(noise_stream),
        .done(noise_done),
        .poly_out(noise_poly_out)
    );
endmodule