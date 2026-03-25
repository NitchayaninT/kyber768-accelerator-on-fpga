// #######################################
// in topmodule we need  to generate r_in somehow!
// ######################################
// -- PRE_ENCRYPTION MODULE --
// SUBMODULE LIST
// 1. sha3_256
// 2. sha3_512
// 3. decode_pk
// 4. decode_msg
// 5. public_matrix_gen
//   5.1 shake128
//   5.2 rejection sampling
// 6. noise_gen
//   6.1 shake256
//   6.2 cbd
// #######################################
// -- STEPS --
// 1. Hash random input r_in to get msg
// 2. Hash encryption_key to get hash_ek
// 3. Concatenate hash_ek || msg, hash again to get coin and pre_k
// 4. Decode msg to get msg_poly
// 5. Decode encryption_key to get rho
// 6. Generate public matrix A from rho
// 7. Generate noise polynomials e1,e2,r from coin and pre_k
// Outputs : msg_poly, e1, e2, r, t_trans, a_t
// #######################################
// Optimization
// 1. Can we just create one shared Keccak 1600 for SHA256,512, SHAKE128, SHAKE256 in order to reduce LUTs?
//  #######################################
// -- FSM --
// IDLE -> HASH_RIN -> HASH_PK -> HASH_BUF0 -> GEN_PUBLIC_MAT -> GEN_NOISE
import params_pkg::*;

module pre_encryption (
    input clk,
    input start,
    input rst,
    //input kem_enc_decap, // flag for encapsulation or decapsulation
    input [KYBER_N - 1:0] r_in,  // in kem_enc : R, in kem_dec : msg'
    input [(KYBER_N)+(KYBER_K * KYBER_RQ_WIDTH * KYBER_N)-1:0] encryption_key,
    input [KYBER_N-1:0]m_prime,//for decrypt
    input [KYBER_N-1:0]c_prime,//for decrypt
    input int mode,
    output logic signed [KYBER_POLY_WIDTH-1:0] e2[0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1:0] e1[0:KYBER_K-1][0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1:0] r[0:KYBER_K-1][0:KYBER_N-1],
    output [(KYBER_N * KYBER_RQ_WIDTH)-1:0] t_vec[3],
    output [KYBER_POLY_WIDTH-1 : 0] a_t[0:(KYBER_K*KYBER_K)-1][0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1 : 0] msg_poly[0:KYBER_N-1],
    output reg [KYBER_N - 1:0] pre_k,
    output reg valid
);

  reg [KYBER_N - 1:0] msg;
  reg [KYBER_N - 1:0] coin;
  reg [KYBER_N - 1:0] rho;
  // Internal variable between module
  reg sha3_valid[3];
  reg sha512_valid;
  reg noise_gen_valid;
  reg public_matrix_valid;
  reg noise_done;
  reg public_matrix_done;
  reg [(KYBER_N * KYBER_RQ_WIDTH)-1:0] msg_poly_packed; // packed version of msg_poly for easier handling in decode_msg
  wire [KYBER_N - 1:0] hash_ek;
  logic [(2 * KYBER_N) - 1:0] buf0;  // store hash(ek),msg
  logic [(2 * KYBER_N) - 1:0] buf1;  // store coin,pre_k
  reg [3:0] public_matrix_poly_index;
  reg public_matrix_poly_valid;

  // SHA modules declaration
  // 1. Hash R (random bits) to get msg
  sha3_256 sha3_uut1 (
      .clk(clk),
      .rst(rst),
      .enable(start&&(mode == ENC)),
      .in(r_in),  // 256 bit random input
      .input_len(256),
      .output_string(msg),  // get msg
      .done(sha3_valid[0])
  );

  // 2. get hash(pk)
  sha3_256 sha3_uut2 (
      .clk(clk),
      .rst(rst),
      .enable(start),
      .in(encryption_key),
      .input_len((KYBER_N) + (KYBER_K * KYBER_RQ_WIDTH * KYBER_N)),  //9472
      .output_string(hash_ek),  //256
      .done(sha3_valid[1])
  );

  // 2.5 Concatenate hash(ek) || msg. msg is at lower bits
  always_comb begin
    if(mode==0)sha512_valid = sha3_valid[0] & sha3_valid[1];
    else if(mode==1)sha512_valid = sha3_valid[1];
    if (sha512_valid&&mode==0) buf0 = {hash_ek, msg};
    else if (sha512_valid&&mode==1) buf0 = {hash_ek, m_prime};//for decrypt
    else buf0 = '0;
  end

  // 3. SHA3-512(SHA3-256(ek) || msg) to generate coin, pre_k
  sha3_512 sha3_uut3 (
      .clk(clk),
      .rst(rst),
      .enable(sha512_valid),
      .in(buf0),  // 512 bits
      .input_len(512),
      .output_string(buf1),
      .done(sha3_valid[2])
  );

  // 3.5 Seperate coin and pre_k from buf1
  always @(posedge clk) begin
    if (rst) begin
      coin  <= 'd0;
      noise_gen_valid <= 1'b0;
      pre_k <= 'd0;
    end else begin
      if (sha3_valid[2]) begin
        pre_k <= buf1[(KYBER_N)-1:0];  // first 256
        coin  <= buf1[(2*KYBER_N)-1:KYBER_N];  //last 256
      end
      noise_gen_valid <= sha3_valid[2];  // Can do noise gen now
    end
  end
  // *** indcpa-enc starts from here ***
  // 4. Decode decompress msg
  logic [KYBER_N-1:0] msg_in;
  assign msg_in = (mode == 0) ? msg : m_prime;//enc -> generated msg, dec -> m_prime
  decode_msg dmsg_uut (
      .msg(msg_in),
      .poly_msg(msg_poly_packed)
  );

  integer i;
  always_comb begin
    for (i = 0; i < KYBER_N; i = i + 1) begin
      msg_poly[i] = $signed({4'b0000, msg_poly_packed[i*12+:12]});
    end
  end

  // 5. Decode PK to get seed (rho) and t trans
  decode_pk dpk_uut (
      .public_key(encryption_key),
      .rho(rho), // this rho is still in reversed order due to pk's input, it will be reversed to the correct order in shake
      .t_trans(t_vec),
      .done(public_matrix_valid)
  );

  // 6. Matrix Generation
  public_matrix_gen pmg_uut (
      .clk(clk),
      .rst(rst),
      .enable(public_matrix_valid),
      .seed(rho),
      .public_matrix_done(public_matrix_done),
      .public_matrix_poly_index(public_matrix_poly_index),
      .public_matrix_poly_valid(public_matrix_poly_valid),
      .A(a_t)
  );

  // 7. Noise Generation
  logic [KYBER_N-1:0] coin_sel;
  assign coin_sel = (mode == 0) ? coin : c_prime;
  noise_gen ng_uut (
      .clk(clk),
      .rst(rst),
      .enable(noise_gen_valid),
      .coin(coin_sel),
      .e2(e2),
      .e1(e1),
      .r(r),
      .noise_done(noise_done)
  );

  // Behavior of the module
  always @(posedge clk) begin
    if (rst) begin
      valid <= 1'b0;
    end else begin
      // when noise gen is done, all outputs are ready
      if (noise_done && public_matrix_done) begin
        valid <= 1'b1;
      end else begin
        valid <= 1'b0;
      end
    end
  end
endmodule

