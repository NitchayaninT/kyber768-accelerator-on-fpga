/*
From pre-decryption to post-decryption.
1. Pre-decryption
    input: ct = (c1,c2), SK = (s,PK,pre-k,coin)
    output c1,c2,s,PK,pre-k,coin
        sk = 19200 bits 
        ct = 8704 bits
        s = [9215:0]sk = 9216 bits
        PK = [18687:9216]sk = 9472 bits
        pre-k = [18943:18688]sk = 256 bits
        coin = [19199:18944]sk = 256 bits
        [7:0]c1[0:959] = [7679:0]ct = 7670 bits
        [7:0]c2[0:127] = [8703:7680]ct = 1024 bits
2. Decode ct
    input: c1,c2 
    output: u,v
        decompress c1 and c2 to u and v
        [7:0] c1 [0:959] = [15:0] u [0:2][0:255] (7670->12288)
        [7:0] c2 [0:127] = [15:0] v [0:255] (1024->4096)
3. Decode sk
    input: s
    output: ~s_T
        original s is s = [9215:0]sk = 9216 bits
        but in this module, 
        s[0:12287]??? -> [4095:0]s[0:2] (256*16)*3
        i think i need to change this? (12288 bits->9216 bits)
        to make it make sense, change the input and output
        [9215:0]s -> [3071:0]~s_T[0:2]
4. NTT module
    input: u 
    output: ~u
        NTT(u) = ~u
5. PACC
    input: ~u, ~s_T
    output: ~a
        ~a= ~s_T*~u
6. INTT module
    input: ~a
    output: a
        NTT^-1(~a) = a
4,5,6 uses main computation module
    input: u, ~s_T -> r,t_s
    output: a -> y
        [15:0] u [0:2][0:255] -> [15:0] r [0:2][0:255] works = 12288 bits
        since u = {Rq Rq Rq} and r = {Sn Sn Sn}
        [3071:0]~s_T[0:2] -> [3071:0] t_s[3] = 9126 bits
        since ~s_T = {Sn Sn Sn} and ~t_T = {P P P}
        and no a_T and no x
        [15:0]a[0:255]->[15:0] v_a(y)[0:255] = 4096 bits
7. Subtraction module
    input: a,v
    output: b
        b = v - a; works
        [15:0]a,v,b[0:255] = 4096 bits
8. Reduce module
    input: b 
    output: b mod q
        b -> b mod q
        modify reduce_top because to take only 1 coefficient
        [11:0] b mod q [0:255] = 3072 bits
9. Compress encode
    input: b mod q
    output: m_prime
        rounds b mod q to m`(3072->256)
10. Post-decryption
    input: m_prime, pre-k, coin, ct
    output: ss
    everything matches, YAYYY!!!
*/
`timescale 1ns/1ps
import params_pkg::*;
import enums_pkg::*;
module decryption_top#(
    parameter SK_WIDTH = (KYBER_N *  KYBER_RQ_WIDTH * KYBER_K) + //s
                         (KYBER_N * KYBER_RQ_WIDTH * KYBER_K) + KYBER_N + // pk
                         (2 * KYBER_N)//pre_k + coin
)(
    input clk,
    input rst,
    input start,
    input  logic [8703:0] ct,
    input  logic [SK_WIDTH-1:0] sk,
    output reg f,
    output logic [KYBER_N-1:0] ss,
    output reg decrypt_done
);
//output for pre-decryption
logic [7:0] c1 [0:959];
logic [7:0] c2 [0:127];
logic [(KYBER_N * KYBER_RQ_WIDTH * KYBER_K)-1:0] s;
logic [(KYBER_N * KYBER_RQ_WIDTH * KYBER_K)+KYBER_N-1:0] PK; 
logic [KYBER_N-1:0] pre_k;
logic [KYBER_N-1:0] coin;
//output for decode ct
logic signed [KYBER_POLY_WIDTH-1:0] u [0:KYBER_K-1][0:KYBER_N-1]; 
logic signed [KYBER_POLY_WIDTH-1:0] v [0:KYBER_N-1];
//output for decode sk
logic [(KYBER_N * KYBER_RQ_WIDTH)-1:0] s_t[0:2];
//output for main computation
logic signed [KYBER_POLY_WIDTH-1:0] a [0:KYBER_N-1];
//output for subtraction module
logic signed [KYBER_POLY_WIDTH-1:0] b [0:KYBER_N-1];
//output for reduce module
logic [KYBER_RQ_WIDTH-1:0] out_v [0:KYBER_N-1];
//output for compress encode
logic [(KYBER_N)-1:0] m;

//done signal
logic pre_dec_valid;
logic decode_ct_done;
logic main_comp_start;
logic main_comp_done;
logic reduce_start;
logic reduce_done;
logic compress_encode_start;
logic compress_encode_done;
logic post_decrypt_start;
assign main_comp_start = decode_ct_done;//start main computation when decode_ct is done
assign reduce_start = main_comp_done;//start reduce when main computation is done
assign compress_encode_start = reduce_done;//start compress_encode when reduce is done
assign post_decrypt_start = compress_encode_done;//start post_decryption when compress_encode is done

pre_decryption pre_decryption_utt(
    .ct(ct),
    .sk(sk),
    .c1(c1),
    .c2(c2),
    .s(s),
    .PK(PK),
    .pre_k(pre_k),
    .coin(coin)
);
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        pre_dec_valid <= 1'b0;
    end else begin
        pre_dec_valid <= start; // 1-cycle pulse after ct/sk are accepted
    end
end

decode_ct decode_ct_utt(
    .clk(clk),
    .rst(rst),
    .enable(pre_dec_valid),
    .c1(c1),
    .c2(c2),
    .u(u),
    .v(v),
    .decompress_done(decode_ct_done)
);

decode_sk decode_sk_uut (
    .s(s),
    .s_t(s_t)
);

main_computation main_computation_uut (
      .clk(clk),
      .reset(rst),
      .enable(main_comp_start),  // start main computation when decode_ct is done
      .mode(DEC),
      .a_t(),
      .t_s(s_t),
      .r_u(u),
      .u(),  // signed
      .v_a(a),  // signed
      .valid(main_comp_done)
  );

subtract subtract_uut (
    .a(v),
    .b(a),
    .r(b)
);

reduce reduce_dec_uut (
    .clk(clk),
    .rst(rst),
    .enable(reduce_start),      //start reduce when main computation is done
    .in_poly(b),
    .busy(),
    .reduce_done(reduce_done),
    .out_poly(out_v)
);
compress_encode_dec compress_encode_dec_utt(
    .clk(clk),
    .rst(rst),
    .enable(compress_encode_start),
    .b(out_v),
    .m(m),
    .done(compress_encode_done)
);
post_decryption post_decryption_uut (
    .clk(clk),
    .rst(rst),
    .enable(post_decrypt_start),
    .m_prime(m),
    .pre_k(pre_k),
    .ct(ct),
    .coin(coin),
    .PK(PK),
    .f(f),
    .ss(ss),
    .decrypt_done(decrypt_done)
);

endmodule
