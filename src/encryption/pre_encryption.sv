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
    output [(`KYBER_POLY_WIDTH * `KYBER_N * `KYBER_K * `KYBER_K) - 1 : 0] a_t,
    output [(`KYBER_RQ_WIDTH * `KYBER_K)-1:0] msg_poly,
    output reg valid
);

  reg [`KYBER_N - 1:0] msg;
  reg [`KYBER_N - 1:0] coin;
  reg [`KYBER_N - 1:0] pre_k;
  // Internal variable between module
  wire sha3_valid[3];
  wire [`KYBER_N - 1:0] hash_ek;
  wire [(2 * `KYBER_N) - 1:0] buf0; // store hash(ek),msg
  wire [(2 * `KYBER_N) - 1:0] buf1; // store coin,pre_k


  // SHA modules declaration
  // randomly select plain text message
  sha3_256 sha3_uut1 (
      .clk(clk),
      .start(start),
      .in(rand_in),
      .out(msg),
      .valid(sha3_valid[0])
  );

  // get hash(ek)
  sha3_256 #(
      .IN_WIDTH((`KYBER_K * `KYBER_R_WIDTH * `KYBER_N) - 1)
  ) sha3_uut2 (
      .clk(clk),
      .in(encryption_key),
      .out(hash_ek),
      .valid(sha3_valid[1])
  );

  sha3_512 sha3_uut3 (
      .clk(clk),
      .in(buf1),
      .out(buf2),
      .valid(sha3_valid[2])
  );

  decode_msg dmsg_uut (

  );
  // Behavior of the module
  always @(posedge clk) begin
    if(rst) begin

    end

  end
endmodule

