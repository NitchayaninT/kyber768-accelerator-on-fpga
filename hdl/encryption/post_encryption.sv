import params_pkg::*;
// *** POST ENCRYPTION MODULE *** //
// ss = SHAKE256(SHA3-256(Ct) || pre_k)
module post_encryption(
    input clk,
    input enable,        // when ct input is available
    input prek_enable,   // when pre_k input is available
    input rst,
    input [KYBER_N - 1:0] pre_k,
    input [7:0]  c1_in [0:959],
    input [7:0]  c2_in [0:127],
    input  logic hash_valid,
    input  logic [5375:0] hash_message_out,

    output logic [8703:0] ct,
    output logic [KYBER_N - 1:0] ss,
    output logic hash_start,
    output logic [1:0]  hash_mode,
    output logic [15:0] hash_input_length,
    output logic        hash_matrix_gen,
    // BRAM write port
    output logic        hash_msg_wr_en,
    output logic [10:0] hash_msg_wr_addr,
    output logic [ 7:0] hash_msg_wr_data,
    output reg encrypt_done
);

typedef enum logic [3:0] {
  PH_IDLE,
  PH_LOAD_CT,       // write 1088 bytes of c1||c2 to BRAM (1088 cycles)
  PH_HASH_CT_START, // assert hash_start for SHA3-256(ct)
  PH_HASH_CT_WAIT,  // wait for hash_valid
  PH_GET_SS,        // wait for prek_enable, then build pre_k||H(ct)
  PH_LOAD_SS,       // write 64 bytes to BRAM
  PH_HASH_SS_START, // assert hash_start for SHAKE256
  PH_HASH_SS_WAIT,  // wait for hash_valid
  PH_DONE
} ph_state_t;

ph_state_t phase;
reg [10:0] load_cnt;

logic [8703:0] ct_hash_input;  // c1||c2 packed (1088 bytes)
logic [511:0]  ct_prek_reg;    // H(ct) || pre_k (64 bytes)
logic [255:0]  ct_hash_reg;    // SHA3-256(ct) result
logic [255:0]  shake_out;      // SHAKE256 result

genvar ss_b;
generate
  for (ss_b = 0; ss_b < 32; ss_b = ss_b + 1) begin : SS_OUTPUT_ORDER
    assign ss[8*(31-ss_b) +: 8] = shake_out[8*ss_b +: 8];
  end
endgenerate

always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    phase             <= PH_IDLE;
    load_cnt          <= '0;
    hash_start        <= 1'b0;
    hash_mode         <= 2'b00;
    hash_input_length <= 16'd0;
    hash_matrix_gen   <= 1'b0;
    hash_msg_wr_en    <= 1'b0;
    hash_msg_wr_addr  <= '0;
    hash_msg_wr_data  <= '0;
    ct                <= '0;
    ct_hash_input     <= '0;
    ct_prek_reg       <= '0;
    ct_hash_reg       <= '0;
    encrypt_done      <= 1'b0;
  end else begin
    hash_start      <= 1'b0;
    hash_msg_wr_en  <= 1'b0;
    hash_matrix_gen <= 1'b0;

    case (phase)
      PH_IDLE: begin
        encrypt_done <= 1'b0;
        if (enable) begin
          integer j;
          // pack c1, c2 into flat registers; also build output ct
          for (j = 0; j < 960; j = j + 1) begin
            ct_hash_input[8*j +: 8]         <= c1_in[j];
            ct[8*(1087-j) +: 8]             <= c1_in[j];
          end
          for (j = 0; j < 128; j = j + 1) begin
            ct_hash_input[8*960 + 8*j +: 8] <= c2_in[j];
            ct[8*(127-j) +: 8]              <= c2_in[j];
          end
          load_cnt <= '0;
          phase    <= PH_LOAD_CT;
        end
      end

      // ct_hash_input stable from previous cycle; write 1088 bytes to BRAM
      PH_LOAD_CT: begin
        hash_msg_wr_en   <= 1'b1;
        hash_msg_wr_addr <= load_cnt;
        hash_msg_wr_data <= ct_hash_input[{load_cnt, 3'b000} +: 8];
        if (load_cnt == 11'd1087) begin
          load_cnt <= '0;
          phase    <= PH_HASH_CT_START;
        end else begin
          load_cnt <= load_cnt + 11'd1;
        end
      end

      PH_HASH_CT_START: begin
        hash_start        <= 1'b1;
        hash_mode         <= 2'b00;   // SHA3-256
        hash_input_length <= 16'd1088; // 1088 bytes = c1+c2
        phase             <= PH_HASH_CT_WAIT;
      end

      PH_HASH_CT_WAIT: begin
        if (hash_valid) begin
          ct_hash_reg <= hash_message_out[255:0];
          phase       <= PH_GET_SS;
        end
      end

      PH_GET_SS: begin
        if (prek_enable) begin
          ct_prek_reg <= {ct_hash_reg, pre_k};  // H(ct) || pre_k = 64 bytes
          load_cnt    <= '0;
          phase       <= PH_LOAD_SS;
        end
      end

      // write 64 bytes of ct_prek_reg to BRAM
      PH_LOAD_SS: begin
        hash_msg_wr_en   <= 1'b1;
        hash_msg_wr_addr <= {5'd0, load_cnt[5:0]};
        hash_msg_wr_data <= ct_prek_reg[{load_cnt[5:0], 3'b000} +: 8];
        if (load_cnt == 11'd63) begin
          load_cnt <= '0;
          phase    <= PH_HASH_SS_START;
        end else begin
          load_cnt <= load_cnt + 11'd1;
        end
      end

      PH_HASH_SS_START: begin
        hash_start        <= 1'b1;
        hash_mode         <= 2'b11;  // SHAKE256
        hash_input_length <= 16'd64; // 64 bytes = H(ct)(32) + pre_k(32)
        phase             <= PH_HASH_SS_WAIT;
      end

      PH_HASH_SS_WAIT: begin
        if (hash_valid) begin
          shake_out    <= hash_message_out[255:0];
          encrypt_done <= 1'b1;
          phase        <= PH_DONE;
        end
      end

      PH_DONE: encrypt_done <= 1'b1;
    endcase
  end
end

endmodule
