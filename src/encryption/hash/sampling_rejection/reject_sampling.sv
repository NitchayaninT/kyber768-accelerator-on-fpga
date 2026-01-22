// Rejection Sampling Module
// Use case : Get a public matrix A transpose
// In kyber, q = 3329 where Rq is a Kyber Ring
// Produces 9 polynomials. 256 coeffs per poly
// coeff is a value from 0 - 3328
// Input : byte stream of 672 bytes (5376 bits)
// Output : 16 x 256 (4096 bits) poly. each coeff is 12 bits BUT stored in 16 bits form
`timescale 1ns / 1ps
module reject_sampling(
    input clk,
    input rst,
    input enable,
    input [5375:0] byte_stream,
    output reg done,
    output reg [4095:0] public_matrix_poly
);
    //parameters
    localparam integer N = 256; // degree of polynomial
    localparam integer Q = 3329; // for Kyber Rq
    localparam integer coeff_width = 16; // each coeff stored in 16 bits

    // Reorder bytes
    wire [5375:0] msg_bits;
    genvar b;
    generate
        for (b = 0; b < 672; b = b + 1) begin : REORDER
            assign msg_bits[b*8 +: 8] = byte_stream[5375-8*b -:8];
        end
    endgenerate

    integer i;
    integer j;
    integer j_next;
    reg running; // flag to indicate if its finished iterating
    reg [11:0] d1,d2; // store 12 bits
    reg [7:0] byte0, byte1, byte2;
    // loop : compute 2 candidates d1, d2 from every 3 bytes (24 bits)
    // 5376/24 bits = 224 iterations
    // d1 = 8 bits of byte 0 + (lower 4 bits of byte 1) << 8
    // d2 = (upper 4 bits of byte 1) >> 4 + byte 2 << 4
    // i = index into the byte stream
    // j = number of accepts coefficients so far
    always @(posedge clk) begin
        if(rst) begin
            public_matrix_poly <= {4096{1'b0}}; // initialize output poly to 0s
            j <= 0;
            i <= 0;
            done <= 1'b0;
            running <= 1'b0;
        end else
            if(enable && !running) begin
                public_matrix_poly <= {4096{1'b0}};
                j <= 0;
                i <= 0;
                done <= 1'b0;
                running <= 1'b1;
            end
            else if(!done && running) begin
                if (i==224 || j >= N) begin
                    running <= 1'b0;
                    //public_matrix_poly <= {4096{1'b0}};
                    done <= 1'b1;
                end
                // process 3 bytes at a time
                byte0 = msg_bits[i*24 +: 8];
                byte1 = msg_bits[i*24 + 8 +: 8];
                byte2 = msg_bits[i*24 + 16 +: 8];
                // get d1 and d2
                d1 = {byte1, byte0} & 12'hfff;
                d2 = ({byte2, byte1} >> 4) & 12'hfff;

                j_next = j;
                // REJECTION RULE. check d1 if its within Q
                if(d1 < Q) begin // yes -> store d1 as the next coeff & increment j
                    public_matrix_poly[j*coeff_width +: coeff_width] <= {4'b0, d1}; // pad upper 4 bits with 0s to make it 16 bits 
                    j = j+1;
                end

                // check d2
                if(d2 < Q && j < N) begin
                    public_matrix_poly[j*coeff_width +: coeff_width] <= {4'b0, d2}; // pad upper 4 bits with 0s to make it 16 bits
                    j = j+1;
                end
                i = i + 1; // move to next 3 bytes
            end
    end
endmodule