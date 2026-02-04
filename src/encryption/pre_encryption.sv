`include "params.vh"

// #######################################
// in topmodule we need  to generate r_in somehow!
// ######################################
module pre_encryption (
    input clk,
    input start,
    input rst,
    input kem_enc_decap, // flag for encapsulation or decapsulation
    input [`KYBER_N - 1:0] r_in, // in kem_enc : R, in kem_dec : msg'
    input [(`KYBER_N)+(`KYBER_K * `KYBER_RQ_WIDTH * `KYBER_N)-1:0] encryption_key,
    output [(`KYBER_N * `KYBER_POLY_WIDTH)-1:0] e2, //flattern
    output [(`KYBER_N * `KYBER_POLY_WIDTH * `KYBER_K)-1:0] e1, //flattern
    output [(`KYBER_N * `KYBER_POLY_WIDTH * `KYBER_K)-1:0] r, //flattern
    output [(`KYBER_N * `KYBER_POLY_WIDTH * `KYBER_K)-1:0] t_trans, //flattern
    output [(`KYBER_POLY_WIDTH * `KYBER_N * `KYBER_K * `KYBER_K) - 1 : 0] a_t,
    output [(`KYBER_RQ_WIDTH * `KYBER_K)-1:0] msg_poly,
    output reg valid
);

  reg [`KYBER_N - 1:0] msg;
  reg [`KYBER_N - 1:0] coin;
  reg [`KYBER_N - 1:0] rho;
  reg [`KYBER_N - 1:0] pre_k;
  // Internal variable between module
  wire sha3_valid[3];
  wire noise_gen_valid;
  wire public_matrix_valid;
  wire noise_done;
  wire public_matrix_done;
  wire [`KYBER_N - 1:0] hash_ek;
  wire [(2 * `KYBER_N) - 1:0] buf0; // store hash(ek),msg
  wire [(2 * `KYBER_N) - 1:0] buf1; // store coin,pre_k

  // SHA modules declaration
  // 1. Hash R (random bits) to get msg
  sha3_256 sha3_uut1 (
      .clk(clk),
      .start(start),
      .in(rand_in), // 256 bit random input
      .out(msg),
      .valid(sha3_valid[0])
  );

  // 2. get hash(pk)
  sha3_256 #(
      .IN_WIDTH((`KYBER_K * `KYBER_R_WIDTH * `KYBER_N) - 1)
  ) sha3_uut2 (
      .clk(clk),
      .in(encryption_key),
      .out(hash_ek),
      .valid(sha3_valid[1])
  );

// 2.5 Concatenate hash(ek) || msg. msg is at higher bits
assign buf0 = {msg, hash_ek};

// 3. SHA3-512(SHA3-256(ek) || msg) to generate coin, pre_k
  sha3_512 sha3_uut3 (
      .clk(clk),
      .in(buf0),
      .out(buf1),
      .valid(sha3_valid[2])
  );

// 3.5 Seperate coin and pre_k from buf1
  always @(posedge clk) begin
    if(rst) begin
      coin <= 'd0;
      pre_k <= 'd0;
    end else begin
      if(sha3_valid[2]) begin
        coin <= buf1[(`KYBER_N)-1:0]; // first 256
        pre_k <= buf1[(2*`KYBER_N)-1:`KYBER_N]; //last 256
      end
      noise_gen_valid <= sha3_valid[2]; // Can do noise gen now
    end
  end

// 4. Decode decompress msg
  decode_msg dmsg_uut (
      .msg(msg),
      .poly_msg(msg_poly)
  );

// 5. Decode PK to get seed (rho)
  decode_pk dpk_uut (
      .public_key(encryption_key),
      .rho(rho),
      .t_trans(t_trans),
      .done(public_matrix_valid)
  );

// 6. Matrix Generation
    public_matrix_gen pmg_uut (
        .clk(clk),
        .enable(public_matrix_valid),
        .seed(rho),
        .public_matrix_done(public_matrix_done),
        .public_matrix_poly_index(),
        .public_matrix_poly_valid(),
        .A(a_t)
    );

// 7. Noise Generation
    noise_gen ng_uut (
        .clk(clk),
        .rst(rst),
        .enable(noise_gen_valid[0]),
        .coin(coin),
        .noise_poly_out_e2(e2),
        .noise_poly_out_e1(e1),
        .noise_poly_out_r(r),
        .noise_done(noise_done)
    );

// Behavior of the module
  always @(posedge clk) begin
    if(rst) begin

    end

  end
endmodule

