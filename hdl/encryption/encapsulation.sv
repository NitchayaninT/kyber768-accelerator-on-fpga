// ENCAPSULATION MODULE
`timescale 1ns / 1ps
import params_pkg::*;

module encapsulation (
    input clk,
    input rst,
    input start,
    input [KYBER_N - 1:0] r_in,  // random input for pre-encryption
    input [(KYBER_N)+(KYBER_K * KYBER_RQ_WIDTH * KYBER_N)-1:0] encryption_key, // public key from keygen
    input [KYBER_N-1:0]m_prime,//for decrypt
    input [KYBER_N-1:0]c_prime,//for decrypt
    input int mode, // ENC =  0, DEC = 1
    output [KYBER_N - 1:0] pre_k,  // pre-k for post-decryption
    output [KYBER_N - 1:0] ss1,
    output [(1088*8)-1:0] ct_out,  // 128 bytes for c2
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
  logic [7:0] c1[0:959];
  logic [7:0] c2[0:127];

  // done signals
  logic pre_enc_done;
  logic main_comp_done;
  logic reduce_done;
  logic compress_done;

  // ---- Shared hash controller signals ----
  // pre_encryption drives these during pre-enc phase
  logic        pre_hash_start;
  logic [1:0]  pre_hash_mode;
  logic [15:0] pre_hash_input_length;
  logic        pre_hash_matrix_gen;
  logic        pre_hash_msg_wr_en;
  logic [10:0] pre_hash_msg_wr_addr;
  logic [ 7:0] pre_hash_msg_wr_data;

  // post_encryption drives these during post-enc phase
  logic        post_hash_start;
  logic [1:0]  post_hash_mode;
  logic [15:0] post_hash_input_length;
  logic        post_hash_matrix_gen;
  logic        post_hash_msg_wr_en;
  logic [10:0] post_hash_msg_wr_addr;
  logic [ 7:0] post_hash_msg_wr_data;

  // Muxed hash controller inputs; post_enc takes over once pre_enc_done goes high
  logic        hash_start;
  logic [1:0]  hash_mode;
  logic [15:0] hash_input_length;
  logic        hash_matrix_gen;
  logic        hash_msg_wr_en;
  logic [10:0] hash_msg_wr_addr;
  logic [ 7:0] hash_msg_wr_data;
  logic [5375:0] hash_message_out;
  logic        hash_valid;

  assign hash_start        = pre_enc_done ? post_hash_start        : pre_hash_start;
  assign hash_mode         = pre_enc_done ? post_hash_mode         : pre_hash_mode;
  assign hash_input_length = pre_enc_done ? post_hash_input_length : pre_hash_input_length;
  assign hash_matrix_gen   = pre_enc_done ? post_hash_matrix_gen   : pre_hash_matrix_gen;
  assign hash_msg_wr_en    = pre_enc_done ? post_hash_msg_wr_en    : pre_hash_msg_wr_en;
  assign hash_msg_wr_addr  = pre_enc_done ? post_hash_msg_wr_addr  : pre_hash_msg_wr_addr;
  assign hash_msg_wr_data  = pre_enc_done ? post_hash_msg_wr_data  : pre_hash_msg_wr_data;

  // Shared hash controller
  hash_controller shared_hash (
      .clk          (clk),
      .rst          (rst),
      .msg_wr_en    (hash_msg_wr_en),
      .msg_wr_addr  (hash_msg_wr_addr),
      .msg_wr_data  (hash_msg_wr_data),
      .enable       (hash_start),
      .hash_mode    (hash_mode),
      .matrix_gen   (hash_matrix_gen),
      .input_length (hash_input_length),
      .message_out  (hash_message_out),
      .valid        (hash_valid)
  );

  pre_encryption pre_enc_inst (
      .clk              (clk),
      .start            (start),
      .rst              (rst),
      .r_in             (r_in),
      .encryption_key   (encryption_key),
      .m_prime(m_prime),//decrypt
      .c_prime(c_prime),//decrypt
      .mode(mode),//ENC =  0, DEC = 1
      .hash_valid       (hash_valid),
      .hash_message_out (hash_message_out),
      .hash_start       (pre_hash_start),
      .hash_mode        (pre_hash_mode),
      .hash_input_length(pre_hash_input_length),
      .hash_matrix_gen  (pre_hash_matrix_gen),
      .hash_msg_wr_en   (pre_hash_msg_wr_en),
      .hash_msg_wr_addr (pre_hash_msg_wr_addr),
      .hash_msg_wr_data (pre_hash_msg_wr_data),
      .e2               (e2),
      .e1               (e1),
      .r                (r),
      .t_vec            (t_vec),
      .a_t              (a_t),
      .msg_poly         (msg_poly),
      .pre_k            (pre_k),
      .valid            (pre_enc_done)
  );

  main_computation main_comp_inst (
      .clk   (clk),
      .reset (rst),
      .enable(pre_enc_done),
      .mode  (0),
      .a_t   (a_t),
      .t_s   (t_vec),
      .r_u   (r),
      .u     (x),
      .v_a   (y),
      .valid (main_comp_done)
  );

  genvar k;
  generate
    for (k = 0; k < KYBER_K; k = k + 1) begin : add_u
      add add_u_inst (.a(x[k]), .b(e1[k]), .r(u[k]));
    end
  endgenerate

  add add_v1_inst (.a(y),       .b(e2),      .r(y_add_e2));
  add add_v2_inst (.a(y_add_e2),.b(msg_poly),.r(v));

  reduce_top reduce_top_inst (
      .clk        (clk),
      .rst        (rst),
      .enable     (main_comp_done),
      .u          (u),
      .v          (v),
      .out_u      (out_u),
      .out_v      (out_v),
      .reduce_done(reduce_done)
  );

  compress_encode #(.Q(KYBER_Q)) compress_enc_inst (
      .enable       (reduce_done),
      .rst          (rst),
      .clk          (clk),
      .u            (out_u),
      .v            (out_v),
      .c1           (c1),
      .c2           (c2),
      .compress_done(compress_done)
  );

  post_encryption post_enc_inst (
      .clk              (clk),
      .enable           (compress_done),
      .prek_enable      (pre_enc_done),
      .rst              (rst),
      .pre_k            (pre_k),
      .c1_in            (c1),
      .c2_in            (c2),
      .ct               (ct_out),
      .ss               (ss1),
      .hash_valid       (hash_valid),
      .hash_message_out (hash_message_out),
      .hash_start       (post_hash_start),
      .hash_mode        (post_hash_mode),
      .hash_input_length(post_hash_input_length),
      .hash_matrix_gen  (post_hash_matrix_gen),
      .hash_msg_wr_en   (post_hash_msg_wr_en),
      .hash_msg_wr_addr (post_hash_msg_wr_addr),
      .hash_msg_wr_data (post_hash_msg_wr_data),
      .encrypt_done     (encrypt_done)
  );
endmodule
