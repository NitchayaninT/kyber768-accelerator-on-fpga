// Rejection Sampling Module
// Use case : Get a public matrix A transpose
// In kyber, q = 3329 where Rq is a Kyber Ring
// Produces 9 polynomials. 256 coeffs per poly
// coeff is a value from 0 - 3328
// Input : byte stream of 672 bytes (5376 bits)
// Output : 16 x 256 (4096 bits) poly. each coeff is 12 bits BUT stored in 16 bits form
`timescale 1ns / 1ps
module reject_sampling #(
    parameter int N  = 256,
    parameter int Q = 3329,
    parameter int NUM_BYTES = 672
    )(
    input clk,
    input rst,
    input enable,
    input [NUM_BYTES*8-1:0] byte_stream,
    output reg done,
    output reg need_more,
    output reg [4095:0] public_matrix_poly
);
    // C: pos is a byte pointer, advances by 3 each iteration
    logic [$clog2(NUM_BYTES+1)-1:0] pos;   // byte pointer 0..NUM_BYTES
    logic [8:0] ctr;                       // accepted coeff counter 0..256
    logic running;

    logic [7:0] b0, b1, b2;
    logic [11:0] d1, d2;

    // helper: read byte k assuming byte0 is in bits [7:0]
    function automatic [7:0] get_byte(input int k);
        get_byte = byte_stream[k*8 +: 8];
    endfunction

    localparam integer coeff_width = 16; // each coeff stored in 16 bits

    // Reorder bytes
    wire [5375:0] msg_bits;
    genvar b;
    generate
        for (b = 0; b < 672; b = b + 1) begin : REORDER
            assign msg_bits[b*8 +: 8] = byte_stream[5375-8*b -:8];
        end
    endgenerate

   always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pos  <= '0;
            ctr  <= '0;
            done <= 1'b0;
            need_more <= 1'b0;
            running <= 1'b0;
            public_matrix_poly <= '0;
        end else begin
            // default
            done <= 1'b0;

            if (enable && !running) begin
                pos  <= 0;
                ctr  <= 0;
                need_more <= 1'b0;
                running <= 1'b1;
                public_matrix_poly <= '0;
            end

            if (running) begin
                // If we already have 256 coeffs -> finish
                if (ctr >= N) begin
                    done <= 1'b1;
                    running <= 1'b0;
                end
                else if (pos + 3 > NUM_BYTES) begin
                    // In C, this is where gen_matrix squeezes more bytes and continues
                    need_more <= 1'b1;
                    done <= 1'b1;      
                    running <= 1'b0;
                end
                else begin
                    // Read 3 bytes
                    b0 <= get_byte(pos+0);
                    b1 <= get_byte(pos+1);
                    b2 <= get_byte(pos+2);

                    // gets d1, d2
                    // d1 = ((b0) | (b1<<8)) & 0xFFF
                    // d2= ((b1>>4) | (b2<<4)) & 0xFFF
                    d1 <= ({get_byte(pos+1), get_byte(pos+0)} & 12'hFFF);
                    d2 <= ((({get_byte(pos+2), get_byte(pos+1)} >> 4)) & 12'hFFF);

                    // Advance pos by 3 (C: pos += 3)
                    pos <= pos + 3;

                    // Accept/reject exactly like C, with ctr increments
                    if (({get_byte(pos+1), get_byte(pos+0)} & 12'hFFF) < Q ) begin
                        public_matrix_poly[ctr*16 +: 16] <= {4'b0, ({get_byte(pos+1), get_byte(pos+0)} & 12'hFFF)};
                        ctr <= ctr + 1;
                    end

                    // val1 only if we still need coeffs
                    if ((ctr < N) && ((({get_byte(pos+2), get_byte(pos+1)} >> 4) & 12'hFFF) < Q)) begin
                        public_matrix_poly[(ctr + ((({get_byte(pos+1), get_byte(pos+0)} & 12'hFFF) < Q ) ? 1 : 0))*16 +: 16]
                            <= {4'b0, (({get_byte(pos+2), get_byte(pos+1)} >> 4) & 12'hFFF)};
                        ctr <= ctr + (((({get_byte(pos+1), get_byte(pos+0)} & 12'hFFF) < Q ) ? 1 : 0) + 1 );
                    end
                end
            end
        end
    end
endmodule