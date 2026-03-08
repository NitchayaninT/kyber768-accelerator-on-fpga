// ENCRYPTION_TOP MODULE
/*
From Pre-Encryption to Post-Encryption
*/
`timescale 1ns / 1ps
import params_pkg::*;

module encryption_top (
    input clk,
    input rst,
    input start,
    input [KYBER_N - 1:0] r_in,  // random input for pre-encryption
    input [(KYBER_N)+(KYBER_K * KYBER_RQ_WIDTH * KYBER_N)-1:0] encryption_key, // public key from keygen
    output [KYBER_N - 1:0] pre_k,  // pre-k for post-decryption
    output [KYBER_N - 1:0] ss1,
    output [(1088*8)-1:0] ct_out,  // 128 bytes for c2
    output reg encrypt_done  // DONE WITH ENCRYPTION AAAAA
);
  integer i, j;
  logic signed [KYBER_POLY_WIDTH-1:0] e2[0:KYBER_N-1];
  logic signed [KYBER_POLY_WIDTH-1:0] e1[0:KYBER_K-1][0:KYBER_N-1];
  logic signed [KYBER_POLY_WIDTH-1:0] r[0:KYBER_K-1][0:KYBER_N-1];
  reg [(KYBER_N * KYBER_RQ_WIDTH)-1:0] t_vec[3];
  reg [KYBER_POLY_WIDTH-1 : 0] a_t[0:(KYBER_K*KYBER_K)-1][0:KYBER_N-1];
  logic signed [KYBER_POLY_WIDTH-1 : 0] msg_poly[0:KYBER_N-1];
  logic signed [15:0] x[0:2][0:255];
  logic signed [15:0] y[0:255];
  logic signed [15:0] u[0:2][0:255];
  logic signed [15:0] v[0:255];
  logic signed [15:0] y_add_e2[0:255];

  logic signed [11:0] out_u[0:2][0:255];
  logic signed [11:0] out_v[0:255];
  logic [7:0] c1[0:959];  // 960 bytes
  logic [7:0] c2[0:127];  // 128 bytes

  // done signals
  logic pre_enc_done;
  logic main_comp_done;
  logic add_u_done;
  logic add_v1_done;
  logic add_v2_done;
  logic add_done;
  logic reduce_done;
  logic compress_done;

  // Pre-encryption
  pre_encryption pre_encryption_uut (
      .clk(clk),
      .start(start),
      .rst(rst),
      .r_in(r_in),
      .encryption_key(encryption_key),
      .e2(e2),
      .e1(e1),
      .r(r),
      .t_vec(t_vec),
      .a_t(a_t),
      .msg_poly(msg_poly),
      .pre_k(pre_k),
      .valid(pre_enc_done)
  );

  // Main computation (NTT, PACC, INTT) 
  // mode 0 for enc
  main_computation main_computation_uut (
      .clk(clk),
      .reset(rst),
      .enable(pre_enc_done),  // start main computation when pre-encryption is done
      .mode(0),
      .a_t(a_t),
      .t_vec(t_vec),
      .r(r),
      .u(x),  // signed
      .v(y),  // signed
      .valid(main_comp_done)
  );

  // Addition
  // generate u
  genvar k;
  generate
    for (k = 0; k < KYBER_K; k = k + 1) begin : add_u
      add add_u_uut (
          .a(x[k]),
          .b(e1[k]),
          .r(u[k])    // output 1
      );
    end
  endgenerate

  // generate v
  add add_v1_uut (
      .a(y),
      .b(e2),
      .r(y_add_e2)
  );

  add add_v2_uut (
      .a(y_add_e2),
      .b(msg_poly),
      .r(v)  // output 2
  );

  // Reduce (need a 2nd top module to control u, v inputs)
  reduce_top reduce_top_uut (
      .clk(clk),
      .rst(rst),
      .enable(main_comp_done),  // start reduce when addition is done
      .u(u),
      .v(v),
      .out_u(out_u),  // store reduced u 
      .out_v(out_v),  // store reduced v 
      .reduce_done(reduce_done)
  );

  compress_encode #(
      .Q(KYBER_Q)
  ) compress_encode (
      .enable       (enable),
      .rst          (rst),
      .clk          (clk),
      .u            (out_u),
      .v            (out_v),
      .c1           (c1),
      .c2           (c2),
      .compress_done(compress_done)
  );

  post_encryption post_encryption_uut (
      .clk(clk),
      .enable(start),  // start post-encryption when pre-encryption is done
      .prek_enable(start),  // start hashing pre-k when pre-encryption is done
      .rst(rst),
      .pre_k(pre_k),
      .ct(ct_out),
      .ss(ss1),
      .encrypt_done(encrypt_done)
  );

endmodule

