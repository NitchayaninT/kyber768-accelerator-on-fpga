`timescale 1ns / 1ps
module decode_ct#(
    parameter int Q = 3329
)(
    input  logic enable,
    input  logic rst,
    input  logic clk,
    input logic [7:0]  c1 [0:959], 
    input logic [7:0]  c2 [0:127], 
    output  logic [15:0] u [0:2][0:255],   
    output  logic [15:0] v [0:255],        
    output logic decompress_done
);
//decompress to 16 bits from 10 bits
    function automatic logic [15:0] decompress10(input logic [9:0] a_in);
        logic [31:0] num;
        begin
        num = a_in * Q + 512;
        decompress10 = num >> 10;
        end
    endfunction
//decompress to 16 bits from 4 bits
    function automatic logic [15:0] decompress4(input logic [3:0] a_in);
        logic [31:0] num;
        begin
        num = a_in * Q + 8;
        decompress4 = num >> 4;
        end
    endfunction
    
    typedef enum logic [1:0] {IDLE, DO_C1, DO_C2, DONE} state_t;
    state_t state;
    logic [9:0] base;
    logic [1:0] poly_i;
    logic [6:0] blk_j;


    // temporary compressed values
    logic [9:0] t0, t1, t2, t3;
    logic [3:0] s0, s1, s2, s3, s4, s5, s6, s7;


    always_ff @(posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            poly_i        <= 0;
            blk_j         <= 0;
            decompress_done <= 1'b0;
        end else begin
            decompress_done <= 1'b0;
            case (state)
                IDLE: begin
                if (enable) begin
                    poly_i <= 0;
                    blk_j  <= 0;
                    state  <= DO_C1;
                end
                end

                DO_C1: begin
                    // iterate 5 bytes per polynomial

                    base = poly_i*320 + blk_j*5;
                    // paste 8 bits into 10 bits, which require 5 8-bits and 4 10-bits
                    t0 = {c1[base+1][1:0],c1[base+0]};
                    t1 = {c1[base+2][3:0],c1[base+1][7:2]};
                    t2 = {c1[base+3][5:0],c1[base+2][7:4]};
                    t3 = {c1[base+4],c1[base+3][7:6]};
                    if (poly_i==0 && blk_j==0) begin
                    $display("t0=%h t1=%h t2=%h t3=%h", t0, t1, t2, t3);
                    $display("d0=%h", decompress10(t0));
                    end
                    //decompress 10bits to 16bits, 4 10-bits -> 4 16-bits
                    //paste 4 16-bits to u, according to polynomial and block(KYBER_N/4)
                    u[poly_i][4*blk_j+0] <= decompress10(t0);
                    u[poly_i][4*blk_j+1] <= decompress10(t1);
                    u[poly_i][4*blk_j+2] <= decompress10(t2);
                    u[poly_i][4*blk_j+3] <= decompress10(t3);

                    if(blk_j==63)begin
                        blk_j<=0;
                        if(poly_i==2)begin
                            state <= DO_C2;
                        end else begin
                        poly_i <= poly_i+1;
                        end
                    end else begin
                        blk_j <= blk_j+1;
                    end
                end

                DO_C2: begin
                    //iterate 4 bytes in c2
                    base = blk_j*4;
                    //paste 8bits into 4bits, which requires 4 8-bits and 8 4-bits
                    s0 = {c2[base+0][3:0]};
                    s1 = {c2[base+0][7:4]};
                    s2 = {c2[base+1][3:0]};
                    s3 = {c2[base+1][7:4]};
                    s4 = {c2[base+2][3:0]};
                    s5 = {c2[base+2][7:4]};
                    s6 = {c2[base+3][3:0]};
                    s7 = {c2[base+3][7:4]};
                    //turn 8 4-bits into 8 16-bits
                    //put back to v according to block (KYBER_N/8)
                    v[8*blk_j+0] <= decompress4(s0);
                    v[8*blk_j+1] <= decompress4(s1);
                    v[8*blk_j+2] <= decompress4(s2);
                    v[8*blk_j+3] <= decompress4(s3);
                    v[8*blk_j+4] <= decompress4(s4);
                    v[8*blk_j+5] <= decompress4(s5);
                    v[8*blk_j+6] <= decompress4(s6);
                    v[8*blk_j+7] <= decompress4(s7);

                    if (blk_j == 31) begin
                        state <= DONE;
                    end else begin
                        blk_j <= blk_j + 1;
                    end
                end
                DONE: begin
                    decompress_done <= 1'b1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule

 