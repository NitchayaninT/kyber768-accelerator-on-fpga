`timescale 1ns / 1ps

import params_pkg::*;

module post_decryption (
    input  logic clk,
    input  logic enable,
    input  logic rst,
    input  logic [KYBER_N-1:0] m_prime,
    input  logic [KYBER_N-1:0] pre_k,
    input  logic [8703:0] ct,
    input  logic [KYBER_N-1:0] coin,
    input  logic [(KYBER_N * KYBER_RQ_WIDTH * KYBER_K)+KYBER_N-1:0] PK,

    input  logic hash_valid,
    input  logic [5375:0] hash_message_out,
    output logic hash_start,
    output logic [1:0] hash_mode,
    output logic [15:0] hash_input_length,
    output logic hash_matrix_gen,
    output logic hash_msg_wr_en,
    output logic [10:0] hash_msg_wr_addr,
    output logic [7:0] hash_msg_wr_data,

    output logic f,
    output logic [KYBER_N-1:0] ss,
    output logic decrypt_done
);

  typedef enum logic [3:0] {
    PH_IDLE,
    PH_LOAD_KR,
    PH_START_KR,
    PH_WAIT_KR,
    PH_ENCRYPT,
    PH_VERIFY,
    PH_LOAD_CT,
    PH_START_CT,
    PH_WAIT_CT,
    PH_PREP_KDF,
    PH_LOAD_KDF,
    PH_START_KDF,
    PH_WAIT_KDF,
    PH_DONE
  } phase_t;

  phase_t phase;
  logic [10:0] load_cnt;

  // Low byte is absorbed first by hash_controller:
  // m_prek_reg = m' || H(pk)
  // kdf_input  = selected key || H(ct)
  logic [511:0] m_prek_reg;
  logic [511:0] kdf_input;
  logic [255:0] ct_hash_reg;
  logic [255:0] c_prime;
  logic [255:0] pre_k_prime;

  logic encryption_start;
  logic encrypt_valid;
  logic [8703:0] ct_prime_output;
  logic [8703:0] ct_prime_stream_order;
  logic [8703:0] ct_prime;

  // encryption_top exposes ciphertext with stream byte 0 at the MSB because
  // that is the convention used by the standalone encryption interface.
  // Decryption stores input stream byte 0 at the LSB. Normalize only here,
  // without changing the already-working encryption output convention.
  genvar ct_byte;
  generate
    for (ct_byte = 0; ct_byte < 1088; ct_byte = ct_byte + 1) begin : G_CT_ORDER
      assign ct_prime_stream_order[8*ct_byte +: 8] =
          ct_prime_output[8*(1087-ct_byte) +: 8];
    end
  endgenerate

  logic debug_kr_hash_seen;
  logic debug_reencrypt_start_seen;
  logic debug_reencrypt_done_seen;
  logic debug_ct_hash_seen;
  logic debug_kdf_hash_seen;
  logic debug_reencrypt_pre_seen;
  logic debug_reencrypt_main_active_seen;
  logic debug_reencrypt_main_seen;
  logic debug_reencrypt_reduce_seen;
  logic debug_reencrypt_compress_seen;

  encryption_top encrypt_post_dec (
      .clk           (clk),
      .rst           (rst),
      .start         (encryption_start),
      .r_in          ('0),
      .encryption_key(PK),
      .m_prime       (m_prime),
      .c_prime       (c_prime),
      .mode          (1),
      .pre_k         (),
      .ss1           (),
      .ct_out        (ct_prime_output),
      .encrypt_done  (encrypt_valid)
  );

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      phase             <= PH_IDLE;
      load_cnt          <= '0;
      m_prek_reg        <= '0;
      kdf_input         <= '0;
      ct_hash_reg       <= '0;
      c_prime           <= '0;
      pre_k_prime       <= '0;
      ct_prime          <= '0;
      encryption_start  <= 1'b0;
      hash_start        <= 1'b0;
      hash_mode         <= 2'b00;
      hash_input_length <= '0;
      hash_matrix_gen   <= 1'b0;
      hash_msg_wr_en    <= 1'b0;
      hash_msg_wr_addr  <= '0;
      hash_msg_wr_data  <= '0;
      f                 <= 1'b0;
      ss                <= '0;
      decrypt_done      <= 1'b0;
      debug_kr_hash_seen        <= 1'b0;
      debug_reencrypt_start_seen <= 1'b0;
      debug_reencrypt_done_seen  <= 1'b0;
      debug_ct_hash_seen         <= 1'b0;
      debug_kdf_hash_seen        <= 1'b0;
      debug_reencrypt_pre_seen      <= 1'b0;
      debug_reencrypt_main_active_seen <= 1'b0;
      debug_reencrypt_main_seen     <= 1'b0;
      debug_reencrypt_reduce_seen   <= 1'b0;
      debug_reencrypt_compress_seen <= 1'b0;
    end else begin
      encryption_start <= 1'b0;
      hash_start       <= 1'b0;
      hash_msg_wr_en   <= 1'b0;
      hash_matrix_gen  <= 1'b0;

      if (encrypt_post_dec.pre_enc_done)
        debug_reencrypt_pre_seen <= 1'b1;
      if (encrypt_post_dec.main_comp_inst.current_state != MC_IDLE)
        debug_reencrypt_main_active_seen <= 1'b1;
      if (encrypt_post_dec.main_comp_done)
        debug_reencrypt_main_seen <= 1'b1;
      if (encrypt_post_dec.reduce_done)
        debug_reencrypt_reduce_seen <= 1'b1;
      if (encrypt_post_dec.compress_done)
        debug_reencrypt_compress_seen <= 1'b1;

      case (phase)
        PH_IDLE: begin
          decrypt_done <= 1'b0;
          if (enable) begin
            m_prek_reg <= {pre_k, m_prime};
            load_cnt   <= '0;
            phase      <= PH_LOAD_KR;
          end
        end

        PH_LOAD_KR: begin
          hash_msg_wr_en   <= 1'b1;
          hash_msg_wr_addr <= load_cnt;
          hash_msg_wr_data <= m_prek_reg[{load_cnt[5:0], 3'b000} +: 8];
          if (load_cnt == 11'd63) begin
            load_cnt <= '0;
            phase    <= PH_START_KR;
          end else begin
            load_cnt <= load_cnt + 11'd1;
          end
        end

        PH_START_KR: begin
          hash_start        <= 1'b1;
          hash_mode         <= 2'b01;  // SHA3-512
          hash_input_length <= 16'd64;
          phase             <= PH_WAIT_KR;
        end

        PH_WAIT_KR: begin
          if (hash_valid) begin
            debug_kr_hash_seen <= 1'b1;
            pre_k_prime      <= hash_message_out[255:0];
            c_prime          <= hash_message_out[511:256];
            debug_reencrypt_start_seen <= 1'b1;
            phase            <= PH_ENCRYPT;
          end
        end

        PH_ENCRYPT: begin
          // Hold start until the nested encryption transaction completes.
          // Its pre_encryption FSM samples start only while in IDLE.
          encryption_start <= 1'b1;
          if (encrypt_valid) begin
            encryption_start <= 1'b0;
            debug_reencrypt_done_seen <= 1'b1;
            ct_prime <= ct_prime_stream_order;
            phase    <= PH_VERIFY;
          end
        end

        PH_VERIFY: begin
          f        <= (ct_prime == ct);
          load_cnt <= '0;
          phase    <= PH_LOAD_CT;
        end

        PH_LOAD_CT: begin
          hash_msg_wr_en   <= 1'b1;
          hash_msg_wr_addr <= load_cnt;
          hash_msg_wr_data <= ct[{load_cnt, 3'b000} +: 8];
          if (load_cnt == 11'd1087) begin
            load_cnt <= '0;
            phase    <= PH_START_CT;
          end else begin
            load_cnt <= load_cnt + 11'd1;
          end
        end

        PH_START_CT: begin
          hash_start        <= 1'b1;
          hash_mode         <= 2'b00;  // SHA3-256
          hash_input_length <= 16'd1088;
          phase             <= PH_WAIT_CT;
        end

        PH_WAIT_CT: begin
          if (hash_valid) begin
            debug_ct_hash_seen <= 1'b1;
            ct_hash_reg <= hash_message_out[255:0];
            phase       <= PH_PREP_KDF;
          end
        end

        PH_PREP_KDF: begin
          // Valid ciphertext: K' || H(ct). Invalid ciphertext: z || H(ct).
          kdf_input <= {ct_hash_reg, (f ? pre_k_prime : coin)};
          load_cnt  <= '0;
          phase     <= PH_LOAD_KDF;
        end

        PH_LOAD_KDF: begin
          hash_msg_wr_en   <= 1'b1;
          hash_msg_wr_addr <= load_cnt;
          hash_msg_wr_data <= kdf_input[{load_cnt[5:0], 3'b000} +: 8];
          if (load_cnt == 11'd63) begin
            load_cnt <= '0;
            phase    <= PH_START_KDF;
          end else begin
            load_cnt <= load_cnt + 11'd1;
          end
        end

        PH_START_KDF: begin
          hash_start        <= 1'b1;
          hash_mode         <= 2'b11;  // SHAKE256
          hash_input_length <= 16'd64;
          phase             <= PH_WAIT_KDF;
        end

        PH_WAIT_KDF: begin
          if (hash_valid) begin
            debug_kdf_hash_seen <= 1'b1;
            ss           <= hash_message_out[255:0];
            decrypt_done <= 1'b1;
            phase        <= PH_DONE;
          end
        end

        PH_DONE: decrypt_done <= 1'b1;
      endcase
    end
  end

endmodule
