// cbd module
// generate noise polynomial
// in kyber768, generate e1, e2, and r
// Input : noise char 1024 bits
// Output : polynomial of degree 256 with coeffs in [-2,2]
// expected output : e,f,0,1,2
`timescale 1ns / 1ps
module cbd
(
    input clk,
    input rst,
    input enable,
    input [1023:0] noise,
    output reg done,
    output reg [4095:0] poly_out // 256 coeffs, each coeff is 16 bits. 128 bytes per poly
);
    // parameters
    localparam integer N = 256; // degree of polynomial
    localparam integer eta = 2; // for kyber768
    localparam integer noise_len = 4096;
    localparam integer coeff_width = 16; // each coeff is 16 bits

    // Reorder bytes
    wire [1023:0] noise_reordered;
    genvar j;
    generate
        for (j = 0; j < 128; j = j + 1) begin : REORDER
            assign noise_reordered[j*8 +: 8] = noise[1023-8*j -:8];
        end
    endgenerate

    // for loop : from 0 to 255
    integer i;
    integer a, b;
    logic signed [coeff_width-1:0] coeff; //16
    always @(posedge clk or posedge rst) begin
        // get a and b for each coeff
        // a = number of 1s in first eta bits (0,1,2)
        // b = number of 1s in next eta bits (0,1,2)
        // coef = a-b, range from [-2,2]
        // but each coef has to be stored in a 16-bit format
        if(rst) begin
            done <= 1'b0;
            poly_out <= 4096'b0;
        end else begin
            for(i = 0; i < N; i = i + 1) begin
                a = 0;
                b = 0;
                for(integer j = 0; j < eta; j = j + 1) begin
                    a = a + noise_reordered[i*(2*eta)+ j];
                    b = b + noise_reordered[i*(2*eta)+ eta + j];
                end
                coeff = $signed(a - b); // in [-2,2] range
                poly_out[i*coeff_width +: coeff_width] <= coeff; // each coef consumes 4 bits. so 256*4 = 1024 bits are produced
            end
            done <= 1'b1;
        end
    end
endmodule