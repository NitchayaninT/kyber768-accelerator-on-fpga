`timescale 1ns / 1ps
module sponge_const (
    input clk,
    input enable,
    input rst,
    input [260:0] in, // coins or seeds
    input [13:0] output_len, 
    output [5376:0] state_out, // 5376 bits is the max output we can get in kyber's shake
    output reg valid
);

endmodule