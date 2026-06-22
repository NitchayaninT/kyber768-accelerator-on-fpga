// #######################################
// in topmodule we need  to generate r_in somehow!
// ######################################
// -- PRE_ENCRYPTION MODULE --
// SUBMODULE LIST
// 1. sha3_256
// 2. sha3_512
// 3. decode_pk
// 4. decode_msg
// 5. public_matrix_gen -> shake128 + reject_sampling
// 6. noise_gen -> shake256 + cbd
// #######################################
// -- FSM --
// IDLE -> HASH_RIN_(LOAD/START/WAIT) -> HASH_PK_(LOAD/START/WAIT) ->
//         HASH_BUF0_(LOAD/START/WAIT) -> START_MATRIX_GEN -> WAIT_MATRIX_GEN ->
//         START_NOISE -> WAIT_NOISE -> DONE
import params_pkg::*;

module pre_encryption (
    input clk,
    input start,
    input rst,
    input [KYBER_N - 1:0] r_in,
    input [(KYBER_N)+(KYBER_K * KYBER_RQ_WIDTH * KYBER_N)-1:0] encryption_key,

    input logic hash_valid,
    input logic [5375:0] hash_message_out,

    // OUTPUTS
    //for decryption, m_prime is used instead of msg from sha3-256, c_prime is used instead of coin in noise generation
    input [KYBER_N-1:0]m_prime,//for decrypt
    input [KYBER_N-1:0]c_prime,//for decrypt
    input int mode,

    output logic signed [KYBER_POLY_WIDTH-1:0] e2[0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1:0] e1[0:KYBER_K-1][0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1:0] r[0:KYBER_K-1][0:KYBER_N-1],
    output [(KYBER_N * KYBER_RQ_WIDTH)-1:0] t_vec[3],
    output signed [KYBER_POLY_WIDTH-1 : 0] a_t[0:(KYBER_K*KYBER_K)-1][0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1 : 0] msg_poly[0:KYBER_N-1],

    // Hash controller interface
    output logic        hash_start,
    output logic [1:0]  hash_mode,
    output logic [15:0] hash_input_length,
    output logic        hash_matrix_gen,
    // BRAM write port
    output logic        hash_msg_wr_en,
    output logic [10:0] hash_msg_wr_addr,
    output logic [ 7:0] hash_msg_wr_data,

    output reg [KYBER_N - 1:0] pre_k,
    output reg valid
);

  reg [KYBER_N - 1:0] msg;
  reg [KYBER_N - 1:0] coin;
  reg [KYBER_N - 1:0] rho;
  logic decode_pk_done;
  logic public_matrix_start;
  reg noise_gen_valid;
  reg public_matrix_valid;
  reg noise_done;
  reg public_matrix_done;
  reg [(KYBER_N * KYBER_RQ_WIDTH)-1:0] msg_poly_packed;
  reg [KYBER_N - 1:0] msg_latched;
  reg [KYBER_N - 1:0] hash_ek_latched;
  logic [(2 * KYBER_N) - 1:0] buf1;
  reg [3:0] public_matrix_poly_index;
  reg public_matrix_poly_valid;

  typedef enum logic [3:0] {
    IDLE,
    HASH_RIN_LOAD,
    HASH_RIN_START,
    HASH_RIN_WAIT,
    HASH_PK_LOAD,
    HASH_PK_START,
    HASH_PK_WAIT,
    HASH_BUF0_LOAD,
    HASH_BUF0_START,
    HASH_BUF0_WAIT,
    START_MATRIX_GEN,
    WAIT_MATRIX_GEN,
    START_NOISE,
    WAIT_NOISE,
    DONE
  } state_t;

  state_t pre_enc_state;

  // public_matrix_gen hash signals
  logic pmg_hash_start;
  logic [1:0]  pmg_hash_mode;
  logic [15:0] pmg_hash_input_length;
  logic pmg_hash_matrix_gen;
  logic pmg_hash_msg_wr_en;
  logic [10:0] pmg_hash_msg_wr_addr;
  logic [ 7:0] pmg_hash_msg_wr_data;

  // noise_gen hash signals
  logic ng_hash_start;
  logic [1:0]  ng_hash_mode;
  logic [15:0] ng_hash_input_length;
  logic ng_hash_matrix_gen;
  logic ng_hash_msg_wr_en;
  logic [10:0] ng_hash_msg_wr_addr;
  logic [ 7:0] ng_hash_msg_wr_data;

  // byte-reverse r_in (MSB-first for SHA3 comparison)
  wire [255:0] rin_reversed;
  genvar b;
  generate
    for (b = 0; b < 32; b = b + 1) begin : REORDER
      assign rin_reversed[b*8 +: 8] = r_in[255-8*b -:8];
    end
  endgenerate

  // *** indcpa-enc starts from here ***
  // 4. Decode decompress msg
  // byte-reverse encryption_key
  wire [9471:0] ek_reversed;
  genvar c;
  generate
    for (c = 0; c < 1184; c = c + 1) begin : REORDER2
      assign ek_reversed[c*8 +: 8] = encryption_key[9471-8*c -:8];
    end
  endgenerate

  // load counter: 11 bits to count up to 1183 (PK load)
  reg [10:0] load_cnt;

  // Packed BUF0 source: {hash_ek_latched, msg_latched} = 64 bytes
  wire [511:0] buf0_data;
  assign buf0_data = {hash_ek_latched, msg_latched};

  // decode_msg
  decode_msg dmsg_uut (
      .msg(msg_latched),
      //.msg(msg_in),
      .poly_msg(msg_poly_packed)
  );

  integer i;
  always_comb begin
    for (i = 0; i < KYBER_N; i = i + 1)
      msg_poly[i] = $signed({4'b0000, msg_poly_packed[i*12+:12]});
  end

  // decode_pk
  decode_pk dpk_uut (
      .public_key(encryption_key),
      .rho(rho),
      .t_trans(t_vec),
      .done(decode_pk_done)
  );

  // public_matrix_gen
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
      .hash_matrix_gen(pmg_hash_matrix_gen),
      .hash_msg_wr_en(pmg_hash_msg_wr_en),
      .hash_msg_wr_addr(pmg_hash_msg_wr_addr),
      .hash_msg_wr_data(pmg_hash_msg_wr_data),
      .public_matrix_done(public_matrix_done),
      .public_matrix_poly_index(public_matrix_poly_index),
      .public_matrix_poly_valid(public_matrix_poly_valid),
      .A(a_t)
  );

  logic [KYBER_N-1:0] coin_sel;
  assign coin_sel = (mode == 0) ? coin : c_prime;
  // noise_gen
  noise_gen ng_uut (
      .clk(clk),
      .rst(rst),
      .enable(noise_gen_valid),
      .coin(coin_sel),
      .hash_valid(hash_valid),
      .hash_message_out(hash_message_out),
      .hash_start(ng_hash_start),
      .hash_mode(ng_hash_mode),
      .hash_input_length(ng_hash_input_length),
      .hash_matrix_gen(ng_hash_matrix_gen),
      .hash_msg_wr_en(ng_hash_msg_wr_en),
      .hash_msg_wr_addr(ng_hash_msg_wr_addr),
      .hash_msg_wr_data(ng_hash_msg_wr_data),
      .e2(e2),
      .e1(e1),
      .r(r),
      .noise_done(noise_done)
  );

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      pre_enc_state    <= IDLE;
      valid            <= 1'b0;
      hash_start       <= 1'b0;
      hash_mode        <= 2'b00;
      hash_input_length <= 16'd0;
      hash_matrix_gen  <= 1'b0;
      hash_msg_wr_en   <= 1'b0;
      hash_msg_wr_addr <= '0;
      hash_msg_wr_data <= '0;
      load_cnt         <= '0;
    end else begin
      hash_start       <= 1'b0;
      hash_msg_wr_en   <= 1'b0;
      public_matrix_start <= 1'b0;
      noise_gen_valid  <= 1'b0;
      valid            <= 1'b0;

      case (pre_enc_state)
        IDLE: begin
          if (start)
            pre_enc_state <= HASH_RIN_LOAD;
        end

        // ---- Hash r_in (32 bytes, SHA3-256) ----
        HASH_RIN_LOAD: begin
          hash_msg_wr_en   <= 1'b1;
          hash_msg_wr_addr <= {6'd0, load_cnt[4:0]};
          hash_msg_wr_data <= rin_reversed[{load_cnt[4:0], 3'b000} +: 8];
          if (load_cnt == 11'd31) begin
            load_cnt      <= '0;
            pre_enc_state <= HASH_RIN_START;
          end else begin
            load_cnt <= load_cnt + 11'd1;
          end
        end

        HASH_RIN_START: begin
          hash_start        <= 1'b1;
          hash_mode         <= 2'b00;  // SHA3-256
          hash_input_length <= 16'd32;
          hash_matrix_gen   <= 1'b0;
          pre_enc_state     <= HASH_RIN_WAIT;
        end

        HASH_RIN_WAIT: begin
          if (hash_valid) begin
            case (mode)
              0 : msg_latched <= hash_message_out[255:0];
              1 : msg_latched <= m_prime;
              default : msg_latched <= '0;
            endcase
            pre_enc_state <= HASH_PK_LOAD;
          end
        end

        // ---- Hash public key (1184 bytes, SHA3-256) ----
        HASH_PK_LOAD: begin
          hash_msg_wr_en   <= 1'b1;
          hash_msg_wr_addr <= load_cnt;
          hash_msg_wr_data <= ek_reversed[{load_cnt, 3'b000} +: 8];
          if (load_cnt == 11'd1183) begin
            load_cnt      <= '0;
            pre_enc_state <= HASH_PK_START;
          end else begin
            load_cnt <= load_cnt + 11'd1;
          end
        end

        HASH_PK_START: begin
          hash_start        <= 1'b1;
          hash_mode         <= 2'b00;  // SHA3-256
          hash_input_length <= 16'd1184;  // 1184 bytes = KYBER_PUBLICKEYBYTES
          hash_matrix_gen   <= 1'b0;
          pre_enc_state     <= HASH_PK_WAIT;
        end

        HASH_PK_WAIT: begin
          if (hash_valid) begin
            hash_ek_latched <= hash_message_out[255:0];
            pre_enc_state   <= HASH_BUF0_LOAD;
          end
        end

        // ---- Hash concat (64 bytes: msg || hash_ek, SHA3-512) ----
        HASH_BUF0_LOAD: begin
          hash_msg_wr_en   <= 1'b1;
          hash_msg_wr_addr <= {5'd0, load_cnt[5:0]};
          hash_msg_wr_data <= buf0_data[{load_cnt[5:0], 3'b000} +: 8];
          if (load_cnt == 11'd63) begin
            load_cnt      <= '0;
            pre_enc_state <= HASH_BUF0_START;
          end else begin
            load_cnt <= load_cnt + 11'd1;
          end
        end

        HASH_BUF0_START: begin
          hash_start        <= 1'b1;
          hash_mode         <= 2'b01;  // SHA3-512
          hash_input_length <= 16'd64;  // 64 bytes = hash_ek(32) + msg(32)
          hash_matrix_gen   <= 1'b0;
          pre_enc_state     <= HASH_BUF0_WAIT;
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
            pre_enc_state       <= WAIT_MATRIX_GEN;
          end
        end

        WAIT_MATRIX_GEN: begin
          // pass through pmg BRAM write and hash control signals
          hash_msg_wr_en   <= pmg_hash_msg_wr_en;
          hash_msg_wr_addr <= pmg_hash_msg_wr_addr;
          hash_msg_wr_data <= pmg_hash_msg_wr_data;
          hash_start       <= pmg_hash_start;
          hash_mode        <= pmg_hash_mode;
          hash_input_length <= pmg_hash_input_length;
          hash_matrix_gen  <= pmg_hash_matrix_gen;

          if (public_matrix_done) begin
            noise_gen_valid <= 1'b1;
            pre_enc_state   <= WAIT_NOISE;
          end
        end

        WAIT_NOISE: begin
          // pass through ng BRAM write and hash control signals
          hash_msg_wr_en   <= ng_hash_msg_wr_en;
          hash_msg_wr_addr <= ng_hash_msg_wr_addr;
          hash_msg_wr_data <= ng_hash_msg_wr_data;
          hash_start       <= ng_hash_start;
          hash_mode        <= ng_hash_mode;
          hash_input_length <= ng_hash_input_length;
          hash_matrix_gen  <= ng_hash_matrix_gen;

          if (noise_done) begin
            valid         <= 1'b1;
            pre_enc_state <= DONE;
          end
        end

        DONE: valid <= 1'b1;
      endcase
    end
  end
endmodule
