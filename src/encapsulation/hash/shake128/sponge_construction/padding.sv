`timescale 1ns / 1ps
module padding #(
    parameter integer R = 1344
)(
    input  [10:0] input_len, // input_length in bits (260)
    output [R-1:0] block_out // padded block (return), output is already wired
);
    reg [R-1:0] pad_block; // use reg for always block
    always @* begin
        pad_block = {R{1'b0}};
        // 1 after the message (after first 260 bits)
        pad_block[input_len] = 1'b1;
        // final 1 at last bit of rate (1344th bit)
        pad_block[R-1] = 1'b1;
    end
    assign block_out = pad_block;
endmodule