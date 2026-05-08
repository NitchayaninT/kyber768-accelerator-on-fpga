`timescale 1ns / 1ps
import params_pkg::*;
module decryption_top_tb;
    logic clk,rst,start;
    logic [8703:0] ct;
    logic [SK_WIDTH-1:0] sk;
    reg f;
    logic [KYBER_N-1:0] ss;
    reg decrypt_done;
    
    decryption_top dut(
        .clk(clk),
        .rst(rst),
        .start(start),
        .ct(ct),
        .sk(sk),
        .f(f),
        .ss(ss),
        .decrypt_done(decrypt_done)
    );
    always @(posedge clk)begin
        $display("t=%0t start=%b pre_dec_valid=%b decode_ct_done=%b main_comp_start=%b 
        main_comp_done=%b reduce_start=%b reduce_done=%b compress_encode_start=%b 
        compress_encode_done=%b post_decrypt_start=%b ",
        $time,
        start,
        dut.pre_dec_valid,
        dut.decode_ct_done,
        dut.main_comp_start,
        dut.main_comp_done,
        dut.reduce_start,
        dut.reduce_done,
        dut.compress_encode_start,
        dut.compress_encode_done,
        dut.post_decrypt_start,
        decrypt_done);
    end

endmodule