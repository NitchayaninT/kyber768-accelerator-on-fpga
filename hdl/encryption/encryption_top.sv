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
    output logic [KYBER_N - 1:0] pre_k,  // pre-k for post-decryption
    output logic [KYBER_N - 1:0] ss1,
    output logic [(1088*8)-1:0] ct_out,  // 128 bytes for c2
    output reg encrypt_done  // DONE WITH ENCRYPTION AAAAA
);
  integer i, j;
  logic signed [KYBER_POLY_WIDTH-1:0] e2[0:KYBER_N-1];
  logic signed [KYBER_POLY_WIDTH-1:0] e1[0:KYBER_K-1][0:KYBER_N-1];
  logic signed [KYBER_POLY_WIDTH-1:0] r[0:KYBER_K-1][0:KYBER_N-1];
  logic [(KYBER_N * KYBER_RQ_WIDTH)-1:0] t_vec[3];
  logic signed [KYBER_POLY_WIDTH-1 : 0] a_t[0:(KYBER_K*KYBER_K)-1][0:KYBER_N-1];
  logic signed [KYBER_POLY_WIDTH-1 : 0] msg_poly [0:KYBER_N-1];
  logic signed [15:0] x[0:2][0:255];
  logic signed [15:0] y[0:255];
  logic signed [15:0] u[0:2][0:255];
  logic signed [15:0] v[0:255];
  logic signed [15:0] y_add_e2[0:255];

  logic [11:0] out_u[0:2][0:255];
  logic [11:0] out_v[0:255];
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

  // for hash controller's signals (so that it only initiates the hash module when needed, not all hashes at the same time)
  logic pre_hash_start;
  logic [1:0] pre_hash_mode;
  logic [15:0] pre_hash_input_length;
  logic [15:0] pre_hash_output_length;
  logic [9471:0] pre_hash_message_in;

  // SIGNALS for hash modules
  logic hash_start;
  logic [1:0] hash_mode;
  logic [15:0] hash_input_length;
  logic [15:0] hash_output_length;
  logic [9471:0] hash_message_in;
  logic [5375:0] hash_message_out;
  logic hash_valid;
  
  assign hash_start         = pre_hash_start;
  assign hash_mode          = pre_hash_mode;
  assign hash_input_length  = pre_hash_input_length;
  assign hash_output_length = pre_hash_output_length;
  assign hash_message_in    = pre_hash_message_in;

// HASH CONTROLLER 
hash_controller shared_hash (
    .clk(clk),
    .rst(rst),
    .enable(hash_start),
    .hash_mode(hash_mode),
    .input_length(hash_input_length),
    .output_length(hash_output_length),
    .message_in(hash_message_in),
    .message_out(hash_message_out),
    .valid(hash_valid) // this is also connected in pre/post enc so that they know when the hash output is valid
);

// State machine for hashing
// for pre-encryption, hashes are called 5 times
// for post-encryption, hashes are called 2 times (hash ct, then hash pre_k+hash_ct)
// Pre-encryption
pre_encryption pre_encryption_uut (
    .clk(clk),
    .start(start),
    .rst(rst),
    .r_in(r_in),
    .encryption_key(encryption_key),

    // shared hash connection
    .hash_valid(hash_valid),
    .hash_message_out(hash_message_out),
    .hash_start(pre_hash_start),
    .hash_mode(pre_hash_mode),
    .hash_input_length(pre_hash_input_length),
    .hash_output_length(pre_hash_output_length),
    .hash_message_in(pre_hash_message_in),

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
      .t_s(t_vec),
      .r_u(r),
      .u(x),  // signed
      .v_a(y),  // signed
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
      .out_u(out_u),  // store reduced u (not signed)
      .out_v(out_v),  // store reduced v (not signed)
      .reduce_done(reduce_done)
  );

  compress_encode #(
      .Q(KYBER_Q)
  ) compress_encode (
      .enable       (reduce_done),  // start compression when reduction is done
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
        .enable(compress_done),
        .prek_enable(pre_enc_done),
        .rst(rst),
        .pre_k(pre_k),
        .c1_in(c1),
        .c2_in(c2),
        .ct(ct_out),
        .ss(ss1),
        // shared hash connection
        .hash_valid(hash_valid),
        .hash_message_out(hash_message_out),
        .hash_start(hash_start),
        .hash_mode(hash_mode),
        .hash_input_length(hash_input_length),
        .hash_output_length(hash_output_length),
        .hash_message_in(hash_message_in),
        .encrypt_done(encrypt_done)
    );
endmodule

