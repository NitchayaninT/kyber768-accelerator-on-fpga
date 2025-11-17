//unused for now
`timescale 1ns / 1ps
module shake128_top #(parameter integer R = 1344) (
    input clk,
    input enable,
    input rst,
    input [255:0] in,
    input [13:0] output_len,
    input [3:0] domain, // domain separator
    output [5375:0] output_string
);
    sponge_const #(
        .R(R)
    ) u_sponge (
        .clk(clk),
        .enable(enable),
        .rst(rst),
        .in(in),
        .domain(domain),
        .output_len(output_len),
        .output_string(output_string)
    );
    //assign state_out = output_string[R-1:0];

endmodule
