/* hash_controller: breaks message_in into rate-sized blocks, feeds sponge_controller
 * one block at a time, accumulates squeeze output into message_out.
 *
 * hash_mode: 00=SHA3-256 (rate=136B, sfx=0x06)
 *            01=SHA3-512 (rate=72B,  sfx=0x06)
 *            10=SHAKE128 (rate=168B, sfx=0x1F)
 *            11=SHAKE256 (rate=136B, sfx=0x1F)
 * Responsible
 * - padding/domain suffix
 * - control multiple absorb
 * - multiple squeeze
 */
`timescale 1ns / 1ps
import params_pkg::*;

module hash_controller (
    input  logic          clk,
    input  logic          rst,
    input  logic          enable,
    input  logic [   1:0] hash_mode,      // 00 sha3-256, 01 sha3-512, 10 shake128, 11 shake256
    input  logic          matrix_gen,     // 1 = 4-squeeze mode for SHAKE128 matrix generation
    input  logic [  15:0] input_length,   // in bytes
    input  logic [  15:0] output_length,  // in bytes (SHAKE; caller slices as needed)
    input  logic [9471:0] message_in,
    output logic [5375:0] message_out,
    output logic          valid
);

  // ---- sponge_controller wires ----
  logic sponge_start;
  logic block_in_ready;
  logic last_block;
  logic sponge_busy;
  logic sponge_perm_done;
  logic [MAX_RATE_BYTES*8-1:0] block_data;
  logic [MAX_RATE_BYTES*8-1:0] sponge_block_out;
  logic sponge_block_out_valid;
  logic sponge_done;

  // specific variable for each HASH
  logic [15:0] rate_bytes;
  logic [ 7:0] domain_suffix;

  always_comb begin
    unique case (hash_mode)
      2'b00: begin  // SHA3-256
        rate_bytes    = 16'd136;  // 1088 bits
        domain_suffix = 8'h06;
      end
      2'b01: begin  // SHA3-512
        rate_bytes    = 16'd72;  // 576 bits
        domain_suffix = 8'h06;
      end
      2'b10: begin  // SHAKE128
        rate_bytes    = 16'd168;  // 1344 bits
        domain_suffix = 8'h1F;
      end
      2'b11: begin  // SHAKE256
        rate_bytes    = 16'd136;  // 1088 bits
        domain_suffix = 8'h1F;
      end
    endcase
  end

  sponge_controller u_sponge (
      .clk            (clk),
      .rst            (rst),
      .start          (sponge_start),
      .rate_bytes     (rate_bytes),
      .block_in_ready (block_in_ready),
      .last_block     (last_block),
      .matrix_gen     (matrix_gen),
      .perm_done      (sponge_perm_done),
      .busy           (sponge_busy),
      .block_in       (block_data),
      .block_out      (sponge_block_out),
      .block_out_valid(sponge_block_out_valid),
      .done           (sponge_done)
  );
  
  // block_start: registered byte offset of current block, updated by addition only —
  // avoids a combinational 16x16 multiplier in the block_data mux
  logic [15:0] block_start;
  logic        is_last_block, is_next_last_block;
  assign is_last_block      = (input_length < block_start + rate_bytes);
  assign is_next_last_block = (input_length < block_start + rate_bytes + rate_bytes);

  always_comb begin
    block_data = '0;
    for (int i = 0; i < MAX_RATE_BYTES; i++) begin
      if (i < rate_bytes) begin
        if ((block_start + i) < input_length)
          block_data[8*i +: 8] = message_in[8*(block_start + i) +: 8];
        else if ((block_start + i) == input_length)
          block_data[8*i +: 8] = domain_suffix;
        // else: stays 0
        if (is_last_block && (i == rate_bytes - 1))
          block_data[8*i +: 8] = block_data[8*i +: 8] | 8'h80;
      end
    end
  end

  // control
  logic       running;
  logic [1:0] squeeze_idx;
  // sponge_start_d: 1-cycle delay so block_in_ready arrives when sponge is in
  //   SC_WAIT_BLOCK_IN (SC_IDLE→SC_INIT consumes one extra cycle before SC_WAIT_BLOCK_IN)
  logic       sponge_start_d;
  // block_out_valid_d: 1-cycle delay so capture happens after sponge's SC_SQUEEZE
  //   NB assignment to block_out takes effect (block_out register valid next cycle)
  logic       block_out_valid_d;

  always_ff @(posedge clk) begin
    if (rst) begin
      running           <= 1'b0;
      block_start       <= '0;
      squeeze_idx       <= '0;
      sponge_start      <= 1'b0;
      sponge_start_d    <= 1'b0;
      block_in_ready    <= 1'b0;
      last_block        <= 1'b0;
      message_out       <= '0;
      valid             <= 1'b0;
      block_out_valid_d <= 1'b0;
    end else begin
      sponge_start      <= 1'b0;
      block_in_ready    <= 1'b0;
      valid             <= 1'b0;
      sponge_start_d    <= sponge_start;
      block_out_valid_d <= sponge_block_out_valid;

      if (enable && !running) begin
        running      <= 1'b1;
        block_start  <= '0;
        squeeze_idx  <= '0;
        message_out  <= '0;
        sponge_start <= 1'b1;
      end

      if (running) begin
        // first block: fire 2 cycles after enable so sponge has reached SC_WAIT_BLOCK_IN
        if (sponge_start_d) begin
          block_in_ready <= 1'b1;
          last_block     <= is_last_block;
        end

        // subsequent blocks: 1 cycle after perm_done (SC_PERMUTE → SC_WAIT_BLOCK_IN)
        if (sponge_perm_done && !is_last_block) begin
          block_start    <= block_start + rate_bytes;
          block_in_ready <= 1'b1;
          last_block     <= is_next_last_block;
        end

        // capture squeeze output 1 cycle after block_out_valid so the sponge's
        // block_out register (updated by SC_SQUEEZE NB) has settled
        if (block_out_valid_d) begin
          message_out[squeeze_idx * (MAX_RATE_BYTES*8) +: MAX_RATE_BYTES*8] <= sponge_block_out;
          squeeze_idx <= squeeze_idx + 2'd1;
        end

        if (sponge_done) begin
          running <= 1'b0;
          valid   <= 1'b1;
        end
      end
    end
  end

endmodule
