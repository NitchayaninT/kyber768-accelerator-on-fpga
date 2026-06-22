/* hash_controller: breaks message into rate-sized blocks, feeds sponge_controller
 * one block at a time, accumulates squeeze output into message_out.
 *
 * Message is written byte-by-byte via the BRAM write port (msg_wr_*) before
 * asserting enable.  No wide flat input bus — avoids the combinational mux tree.
 *
 * hash_mode: 00=SHA3-256 (rate=136B, sfx=0x06)
 *            01=SHA3-512 (rate=72B,  sfx=0x06)
 *            10=SHAKE128 (rate=168B, sfx=0x1F)
 *            11=SHAKE256 (rate=136B, sfx=0x1F)
 */
`timescale 1ns / 1ps
import params_pkg::*;

module hash_controller (
    input  logic          clk,
    input  logic          rst,

    // Message BRAM write port — caller loads bytes before asserting enable
    input  logic          msg_wr_en,
    input  logic [10:0]   msg_wr_addr,  // byte address 0..1183
    input  logic [ 7:0]   msg_wr_data,

    input  logic          enable,
    input  logic [ 1:0]   hash_mode,
    input  logic          matrix_gen,
    input  logic [15:0]   input_length,  // bytes

    output logic [5375:0] message_out,
    output logic          valid
);

  // ---- rate/suffix from hash_mode ----
  logic [15:0] rate_bytes;
  logic [ 7:0] domain_suffix;
  always_comb begin
    unique case (hash_mode)
      2'b00: begin rate_bytes = 16'd136; domain_suffix = 8'h06; end
      2'b01: begin rate_bytes = 16'd72;  domain_suffix = 8'h06; end
      2'b10: begin rate_bytes = 16'd168; domain_suffix = 8'h1F; end
      2'b11: begin rate_bytes = 16'd136; domain_suffix = 8'h1F; end
    endcase
  end

  // ---- internal message BRAM (1184 bytes × 8 bits) ----
  localparam int MSG_BRAM_DEPTH = 1184;
  logic [7:0] msg_bram [0:MSG_BRAM_DEPTH-1];
  logic [7:0] bram_rd_data;
  logic [10:0] bram_rd_addr;

  always_ff @(posedge clk) begin
    if (msg_wr_en)
      msg_bram[msg_wr_addr] <= msg_wr_data;
    bram_rd_data <= msg_bram[bram_rd_addr];  // 1-cycle read latency
  end

  // ---- sponge_controller wires ----
  logic sponge_start;
  logic block_in_ready;
  logic last_block;
  logic [MAX_RATE_BYTES*8-1:0] block_data;
  logic [MAX_RATE_BYTES*8-1:0] sponge_block_out;
  logic sponge_block_out_valid;
  logic sponge_perm_done;
  logic sponge_done;

  sponge_controller u_sponge (
      .clk            (clk),
      .rst            (rst),
      .start          (sponge_start),
      .rate_bytes     (rate_bytes),
      .block_in_ready (block_in_ready),
      .last_block     (last_block),
      .matrix_gen     (matrix_gen),
      .perm_done      (sponge_perm_done),
      .busy           (),
      .block_in       (block_data),
      .block_out      (sponge_block_out),
      .block_out_valid(sponge_block_out_valid),
      .done           (sponge_done)
  );

  // ---- block counters ----
  logic [15:0] block_start;   // byte offset of the block currently being fetched
  logic [ 7:0] fetch_cnt;     // 0..rate_bytes; counts cycles spent in HC_FETCH
  logic [ 1:0] squeeze_idx;
  logic        block_out_valid_d;

  // Combinational last-block flags (addition only, no multiplier)
  logic is_last_block, is_next_last_block;
  assign is_last_block      = (input_length < block_start + rate_bytes);
  assign is_next_last_block = (input_length < block_start + rate_bytes + rate_bytes);

  // BRAM read address: block_start + current fetch_cnt
  logic [15:0] bram_addr_wide;
  assign bram_addr_wide = block_start + {8'd0, fetch_cnt};
  assign bram_rd_addr   = (bram_addr_wide < MSG_BRAM_DEPTH) ? bram_addr_wide[10:0] : 11'd0;

  // When fetch_cnt >= 1, BRAM data for byte (fetch_cnt-1) has arrived
  logic [15:0] gidx;      // global byte index of arrived BRAM data
  logic [ 7:0] fetch_slot; // byte slot within block_data (fetch_cnt - 1)
  assign gidx       = block_start + {8'd0, fetch_cnt} - 16'd1;
  assign fetch_slot = fetch_cnt - 8'd1;

  // Byte to store into block_data this cycle (valid when fetch_cnt >= 1)
  logic [7:0] fetch_byte;
  always_comb begin
    if (gidx < input_length)
      fetch_byte = bram_rd_data;
    else if (gidx == input_length)
      fetch_byte = domain_suffix;
    else
      fetch_byte = 8'h00;
    // OR 0x80 into last byte of last block
    if (is_last_block && ({8'd0, fetch_slot} == rate_bytes - 16'd1))
      fetch_byte = fetch_byte | 8'h80;
  end

  // ---- FSM ----
  typedef enum logic [1:0] {
    HC_IDLE,
    HC_FETCH,
    HC_SEND_BLOCK,
    HC_WAIT_PERM
  } hc_state_e;

  hc_state_e state;

  always_ff @(posedge clk) begin
    if (rst) begin
      state             <= HC_IDLE;
      block_start       <= '0;
      fetch_cnt         <= '0;
      squeeze_idx       <= '0;
      sponge_start      <= 1'b0;
      block_in_ready    <= 1'b0;
      last_block        <= 1'b0;
      block_data        <= '0;
      message_out       <= '0;
      valid             <= 1'b0;
      block_out_valid_d <= 1'b0;
    end else begin
      // defaults cleared each cycle
      sponge_start      <= 1'b0;
      block_in_ready    <= 1'b0;
      valid             <= 1'b0;
      block_out_valid_d <= sponge_block_out_valid;

      // capture squeeze output one cycle after block_out_valid (NB latency)
      if (block_out_valid_d) begin
        message_out[squeeze_idx * (MAX_RATE_BYTES*8) +: MAX_RATE_BYTES*8] <= sponge_block_out;
        squeeze_idx <= squeeze_idx + 2'd1;
      end

      case (state)
        HC_IDLE: begin
          if (enable) begin
            block_start  <= '0;
            fetch_cnt    <= '0;
            squeeze_idx  <= '0;
            message_out  <= '0;
            sponge_start <= 1'b1;
            state        <= HC_FETCH;
          end
        end

        // Read bytes from BRAM one per cycle, build block_data register
        HC_FETCH: begin
          // fetch_cnt=0: address bram[block_start] presented; no data yet
          // fetch_cnt=i≥1: bram_rd_data = bram[block_start+(i-1)]; write to block_data[i-1]
          if (fetch_cnt >= 8'd1)
            block_data[{fetch_slot, 3'b000} +: 8] <= fetch_byte; // fetch_slot<<3, no overflow

          if ({8'd0, fetch_cnt} == rate_bytes) begin
            // Last byte written; move to send
            fetch_cnt <= '0;
            state     <= HC_SEND_BLOCK;
          end else begin
            fetch_cnt <= fetch_cnt + 8'd1;
          end
        end

        HC_SEND_BLOCK: begin
          block_in_ready <= 1'b1;
          last_block     <= is_last_block;
          state          <= HC_WAIT_PERM;
        end

        HC_WAIT_PERM: begin
          if (sponge_done) begin
            valid <= 1'b1;
            state <= HC_IDLE;
          end else if (sponge_perm_done && !is_last_block) begin
            block_start <= block_start + rate_bytes;
            fetch_cnt   <= '0;
            state       <= HC_FETCH;
          end
        end
      endcase
    end
  end

endmodule
