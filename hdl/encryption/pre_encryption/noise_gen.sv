// == NOISE GENERATOR MODULE == //
/* Uses SHAKE256 to generate random stream from seed (coin) and nonce
and use cbd to generate noise polynomials */
/* poly count 0-2 = r, 3-5 = e1, 6 = e2 */
import params_pkg::*;
module noise_gen (
    input clk,
    input rst,
    input enable,
    input [255:0] coin,
    input  logic hash_valid,
    input  logic [5375:0] hash_message_out,
    output reg noise_done,
    output logic signed [KYBER_POLY_WIDTH-1:0] r[0:KYBER_K-1][0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1:0] e1[0:KYBER_K-1][0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1:0] e2[0:KYBER_N-1],

    // HASH CONTROLS OUTPUTS
    output logic hash_start,
    output logic [1:0]  hash_mode,
    output logic [15:0] hash_input_length,
    output logic hash_matrix_gen,
    // BRAM write port for message bytes
    output logic        hash_msg_wr_en,
    output logic [10:0] hash_msg_wr_addr,
    output logic [ 7:0] hash_msg_wr_data
);
  logic [4095:0] noise_poly_out;
  reg [2:0] noise_poly_index;
  reg noise_poly_valid;
  reg [1023:0] noise_stream;
  reg [7:0] nonce;

  logic [263:0] shake256_input;
  assign shake256_input = {nonce, coin};  // 33 bytes: coin[0..31], nonce[32]

  logic cbd_enable;
  wire  cbd_done;

  cbd cbd_module (
      .clk(clk),
      .rst(rst),
      .enable(cbd_enable),
      .noise(noise_stream),
      .done(cbd_done),
      .poly_out(noise_poly_out)
  );

  localparam IDLE       = 3'd0;
  localparam SHAKE_LOAD = 3'd1;  // write 33 bytes to hash_controller BRAM
  localparam SHAKE_START = 3'd2;
  localparam WAIT_SHAKE = 3'd3;
  localparam CBD_START  = 3'd4;
  localparam RESET_CBD  = 3'd5;
  localparam WAIT_CBD   = 3'd6;
  localparam POLY_READY = 3'd7;
  localparam DONE       = 4'd8;

  reg [3:0] state_reg;
  reg [5:0] load_cnt;   // counts 0..32 (33 bytes)

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_reg        <= IDLE;
      nonce            <= 8'd0;
      load_cnt         <= '0;
      cbd_enable       <= 1'b0;
      noise_done       <= 1'b0;
      noise_poly_valid <= 1'b0;
      noise_stream     <= '0;
      noise_poly_index <= '0;
      hash_start       <= 1'b0;
      hash_mode        <= 2'b00;
      hash_input_length <= 16'd0;
      hash_matrix_gen  <= 1'b0;
      hash_msg_wr_en   <= 1'b0;
      hash_msg_wr_addr <= '0;
      hash_msg_wr_data <= '0;
    end else begin
      cbd_enable       <= 1'b0;
      noise_poly_valid <= 1'b0;
      hash_start       <= 1'b0;
      hash_msg_wr_en   <= 1'b0;

      case (state_reg)
        IDLE: begin
          noise_done <= 1'b0;
          if (enable) begin
            nonce            <= 8'd0;
            noise_poly_index <= 0;
            load_cnt         <= '0;
            state_reg        <= SHAKE_LOAD;
          end
        end

        SHAKE_LOAD: begin
          // Write one byte per cycle: shake256_input[load_cnt*8+:8]
          hash_msg_wr_en   <= 1'b1;
          hash_msg_wr_addr <= {5'd0, load_cnt};
          hash_msg_wr_data <= shake256_input[{load_cnt, 3'b000} +: 8];
          if (load_cnt == 6'd32) begin
            load_cnt  <= '0;
            state_reg <= SHAKE_START;
          end else begin
            load_cnt <= load_cnt + 6'd1;
          end
        end

        SHAKE_START: begin
          hash_start        <= 1'b1;
          hash_mode         <= 2'b11;  // SHAKE256
          hash_input_length <= 16'd33; // 33 bytes = coin(32) + nonce(1)
          hash_matrix_gen   <= 1'b0;
          state_reg         <= WAIT_SHAKE;
        end

        WAIT_SHAKE: begin
          if (hash_valid) begin
            noise_stream <= hash_message_out[1023:0];
            state_reg    <= CBD_START;
          end
        end

        CBD_START: begin
          cbd_enable <= 1'b1;
          state_reg  <= RESET_CBD;
        end

        RESET_CBD: state_reg <= WAIT_CBD;

        WAIT_CBD: begin
          if (cbd_done) begin
            cbd_enable       <= 1'b0;
            noise_poly_valid <= 1'b1;
            state_reg        <= POLY_READY;
          end
        end

        POLY_READY: begin
          if (nonce == 6) begin
            state_reg <= DONE;
          end else begin
            if (nonce % 3 == 2)
              noise_poly_index <= 1'b0;
            else
              noise_poly_index <= noise_poly_index + 1;
            nonce     <= nonce + 1;
            load_cnt  <= '0;
            state_reg <= SHAKE_LOAD;
          end
        end

        DONE: noise_done <= 1'b1;
      endcase
    end
  end

  integer c;
  always_ff @(posedge clk) begin
    if (noise_poly_valid) begin
      if (nonce <= 2) begin
        for (c = 0; c < 256; c++)
          r[noise_poly_index][c] <= $signed(noise_poly_out[c*16+:16]);
      end else if (nonce <= 5) begin
        for (c = 0; c < 256; c++)
          e1[noise_poly_index][c] <= $signed(noise_poly_out[c*16+:16]);
      end else begin
        for (c = 0; c < 256; c++)
          e2[c] <= $signed(noise_poly_out[c*16+:16]);
      end
    end
  end
endmodule
