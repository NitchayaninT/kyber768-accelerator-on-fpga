`timescale 1ns / 1ps
module padding #(
    parameter integer R = 1344
)(
    input  [10:0] input_len, // input_length in bits (272)
    input wire [7:0] suffix, // 8'h1F for SHAKE
    output [R-1:0] block_out // padded block (return), output is already wired
);
    reg [R-1:0] pad_block; // use reg for always block
    integer k;

    always @* begin
        pad_block = {R{1'b0}};
        // XOR the suffix bits
        for(k=0; k<8; k=k+1) begin
            if ((input_len + k) < R)
                pad_block[input_len+k] = suffix[k];
        end
        // final bit of padding at the end of rate
        pad_block[R-1] = pad_block[R-1] ^ 1'b1;
    end
    assign block_out = pad_block;
endmodule