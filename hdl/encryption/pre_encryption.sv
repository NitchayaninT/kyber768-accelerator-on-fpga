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

    // HASH CONTROLS INPUTS
    input logic hash_valid,
    input logic [5375:0] hash_message_out,

    // OUTPUTS
    /*for decryption, m_prime is used instead of msg from sha3-256, c_prime is used instead of coin in noise generation
    input [KYBER_N-1:0]m_prime,//for decrypt
    input [KYBER_N-1:0]c_prime,//for decrypt
    input int mode,
    */
    output logic signed [KYBER_POLY_WIDTH-1:0] e2[0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1:0] e1[0:KYBER_K-1][0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1:0] r[0:KYBER_K-1][0:KYBER_N-1],
    output [(KYBER_N * KYBER_RQ_WIDTH)-1:0] t_vec[3],
    output signed [KYBER_POLY_WIDTH-1 : 0] a_t[0:(KYBER_K*KYBER_K)-1][0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1 : 0] msg_poly[0:KYBER_N-1],

    // HASH CONTROL PORTS (controls by encryption_top)
    output logic hash_start,
    output logic [1:0] hash_mode,
    output logic [15:0] hash_input_length,
    output logic [15:0] hash_output_length,
    output logic [9471:0] hash_message_in,
    output reg [KYBER_N - 1:0] pre_k,
    output reg valid
);

  reg [KYBER_N - 1:0] msg;
  reg [KYBER_N - 1:0] coin;
  reg [KYBER_N - 1:0] rho;
  // Internal variable between module
 // reg sha3_valid[3];
 // reg sha512_valid;
  logic decode_pk_done;
  logic public_matrix_start;
  //reg msg_done;
  //reg hash_ek_done;
  //reg sha512_started;
  reg noise_gen_valid;
  reg public_matrix_valid;
  reg noise_done;
  reg public_matrix_done;
  reg [(KYBER_N * KYBER_RQ_WIDTH)-1:0] msg_poly_packed; // packed version of msg_poly for easier handling in decode_msg
  reg [KYBER_N - 1:0] msg_latched;
  reg [KYBER_N - 1:0] hash_ek_latched;
  //logic [(2 * KYBER_N) - 1:0] buf0;  // store hash(ek),msg
  logic [(2 * KYBER_N) - 1:0] buf1;  // store coin,pre_k
  reg [3:0] public_matrix_poly_index;
  reg public_matrix_poly_valid;

typedef enum logic [3:0] {
    IDLE,
    HASH_RIN_START,
    HASH_RIN_WAIT,
    HASH_PK_START,
    HASH_PK_WAIT,
    HASH_BUF0_START,
    HASH_BUF0_WAIT,
    START_MATRIX_GEN,
    WAIT_MATRIX_GEN,
    START_NOISE,
    WAIT_NOISE,
    DONE
} state_t;
/*for decryption, sha3-256 only activates when encryption only because decryption uses m_prime instead
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
*/
state_t pre_enc_state;
// public matrix hash request
logic pmg_hash_start;
logic [1:0]  pmg_hash_mode;
logic [15:0] pmg_hash_input_length;
logic [15:0] pmg_hash_output_length;
logic [9471:0] pmg_hash_message_in;

// noise hash request
logic ng_hash_start;
logic [1:0]  ng_hash_mode;
logic [15:0] ng_hash_input_length;
logic [15:0] ng_hash_output_length;
logic [9471:0] ng_hash_message_in;
/* for decryption
  // 2.5 Concatenate hash(ek) || msg. msg is at lower bits. Concatenate hash(ek) || m_prime if decryption
  always_comb begin
    if(mode==0)sha512_valid = sha3_valid[0] & sha3_valid[1];
    else if(mode==1)sha512_valid = sha3_valid[1];
    if (sha512_valid&&mode==0) buf0 = {hash_ek, msg};
    else if (sha512_valid&&mode==1) buf0 = {hash_ek, m_prime};//for decrypt
    else buf0 = '0;
  end
*/

  // reverse order of bits for sha3-256 in pre encryption (so that the order can be comparable with C, otherwise the input would be in an incorrect order)
  // reason : rin and ek are DIRECT inputs from testbench
  // for Rin
  wire [255:0] rin_reversed;
    genvar b;
    generate
        for (b = 0; b < 32; b = b + 1) begin : REORDER // so that the left most bits will be read first
            assign rin_reversed[b*8 +: 8] = r_in[255-8*b -:8];
        end
    endgenerate
  // for encryption key
  wire [9471:0] ek_reversed;
    genvar c;
    generate
        for (c = 0; c < 1184; c = c + 1) begin : REORDER2 // so that the left most bits will be read first
            assign ek_reversed[c*8 +: 8] = encryption_key[9471-8*c -:8];
        end
    endgenerate

  // *** indcpa-enc starts from here ***
  // 4. Decode decompress msg
  /* use m_prime instead of msg for decryption
  logic [KYBER_N-1:0] msg_in;
  assign msg_in = (mode == 0) ? msg : m_prime;//enc -> generated msg, dec -> m_prime*/
  decode_msg dmsg_uut (
      .msg(msg_latched),
      //.msg(msg_in),
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
      .done(decode_pk_done)
  );

  // 6. Matrix Generation
public_matrix_gen pmg_uut (
    .clk(clk),
    .rst(rst),
    .enable(public_matrix_start),
    .seed(rho),

    .hash_valid(hash_valid),
    .hash_message_out(hash_message_out),
    .hash_start(pmg_hash_start),
    .hash_mode(pmg_hash_mode),
    .hash_input_length(pmg_hash_input_length),
    .hash_output_length(pmg_hash_output_length),
    .hash_message_in(pmg_hash_message_in),

    .public_matrix_done(public_matrix_done),
    .public_matrix_poly_index(public_matrix_poly_index),
    .public_matrix_poly_valid(public_matrix_poly_valid),
    .A(a_t)
);
  // 7. Noise Generation
noise_gen ng_uut (
    .clk(clk),
    .rst(rst),
    .enable(noise_gen_valid),
    .coin(coin),

    .hash_valid(hash_valid),
    .hash_message_out(hash_message_out),
    .hash_start(ng_hash_start),
    .hash_mode(ng_hash_mode),
    .hash_input_length(ng_hash_input_length),
    .hash_output_length(ng_hash_output_length),
    .hash_message_in(ng_hash_message_in),

    .e2(e2),
    .e1(e1),
    .r(r),
    .noise_done(noise_done)
);
/* // use c_prime instead of coin in decryption
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
*/
  // Behavior of the module
always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    pre_enc_state <= IDLE;
    valid <= 1'b0;
    hash_start <= 1'b0;
    hash_mode <= 2'b00;
    hash_input_length <= 16'd0;
    hash_output_length <= 16'd0;
    hash_message_in <= '0;
  end else begin
    hash_start <= 1'b0;
    public_matrix_start <= 1'b0;
    noise_gen_valid <= 1'b0;
    valid <= 1'b0;

    case (pre_enc_state)
      IDLE: begin
        if (start) begin
          pre_enc_state <= HASH_RIN_START;
        end
      end

      HASH_RIN_START: begin
        hash_start <= 1'b1;
        hash_mode <= 2'b00; // SHA3-256
        hash_input_length <= 16'd256;
        hash_output_length <= 16'd256;
        hash_message_in <= '0;
        hash_message_in[255:0] <= rin_reversed;

        pre_enc_state <= HASH_RIN_WAIT;
      end

      HASH_RIN_WAIT: begin
        if (hash_valid) begin
          msg_latched <= hash_message_out[255:0];
          pre_enc_state <= HASH_PK_START;
        end
      end

      HASH_PK_START: begin
        hash_start <= 1'b1;
        hash_mode <= 2'b00; // SHA3-256
        hash_input_length <= 16'd9472;
        hash_output_length <= 16'd256;
        hash_message_in <= ek_reversed;

        pre_enc_state <= HASH_PK_WAIT;
      end

      HASH_PK_WAIT: begin
        if (hash_valid) begin
          hash_ek_latched <= hash_message_out[255:0];
          pre_enc_state <= HASH_BUF0_START;
        end
      end

      HASH_BUF0_START: begin
        hash_start <= 1'b1;
        hash_mode <= 2'b01;// SHA3-512
        hash_input_length <= 16'd512;
        hash_output_length <= 16'd512;
        hash_message_in <= '0;
        hash_message_in[511:0] <= {hash_ek_latched, msg_latched};

        pre_enc_state <= HASH_BUF0_WAIT;
      end

      HASH_BUF0_WAIT: begin
        if (hash_valid) begin
          buf1 <= hash_message_out[511:0];
          pre_k <= hash_message_out[255:0];
          coin  <= hash_message_out[511:256];

          pre_enc_state <= START_MATRIX_GEN;
        end
      end

      START_MATRIX_GEN: begin
        if (decode_pk_done) begin
          public_matrix_start <= 1'b1;
          pre_enc_state <= WAIT_MATRIX_GEN;
        end
      end

      WAIT_MATRIX_GEN: begin
        hash_start <= pmg_hash_start;
        hash_mode <= pmg_hash_mode;
        hash_input_length <= pmg_hash_input_length;
        hash_output_length <= pmg_hash_output_length;
        hash_message_in <= pmg_hash_message_in;

      if (public_matrix_done) begin
        noise_gen_valid <= 1'b1;
        pre_enc_state <= WAIT_NOISE;
      end
    end

    WAIT_NOISE: begin
      hash_start <= ng_hash_start;
      hash_mode <= ng_hash_mode;
      hash_input_length <= ng_hash_input_length;
      hash_output_length <= ng_hash_output_length;
      hash_message_in <= ng_hash_message_in;

      if (noise_done) begin
        valid <= 1'b1;
        pre_enc_state <= DONE;
      end
    end

      DONE: begin
        valid <= 1'b1;
      end

    endcase
  end
end
endmodule

