/* ## sponge_controller (Control absorb/pad/squeeze)= handles SHA3/SHAKE behavior
replaces the old seperated hashes into "sponge controller"
- rate selection
- padding/domain suffix
- absorb
- squeeze
- output length */

/* change 
Problem : large message input/output -> large size register with variable indexing consume large LUT
Fix : fix size input for sponge_controller => only one rate block at a time
*/

`timescale 1ns / 1ps
localparam int MAX_RATE_BYTES = 168; // max rate in bytes among the 4 modes (shake128 with 1344 bits)
module sponge_controller (
    input logic clk,
    input logic rst,

    input logic start,
    input logic block_in_ready,
    input logic last_block,  // marks final absorb block → transition to squeeze
    input logic matrix_gen,  // 3 rounds of permute+squeeze (SHAKE128 matrix generation)
    output logic busy,

    input logic [1:0] hash_mode,  // 00 sha3-256, 01 sha3-512, 10 shake128, 11 shake256

    input logic [MAX_RATE_BYTES*8-1:0] block_in,
    output logic [MAX_RATE_BYTES*8-1:0] block_out,
    output logic block_out_valid,
    output logic done
);

  // FSM. Only squeezes once because it only produces 256 bits output
  typedef enum logic [3:0] {
    SC_IDLE,
    SC_INIT,
    SC_WAIT_BLOCK_IN,
    SC_ABSORB,
    SC_PERMUTE,
    SC_SQUEEZE,
    SC_DONE
  } sponge_control_state_t;
  sponge_control_state_t current_state, next_state;

  logic [1599:0] state_reg;
  logic [1:0] squeeze_count;  // use if matrix_gen

  // specific variable for each HASH
  logic [15:0] rate_bytes;
  logic [7:0] domain_suffix;
  always_comb begin
    case (hash_mode)
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

  // permutation
  logic perm_enable;
  logic [1599:0] perm_out;
  logic perm_valid;
  permutation u_perm (
      .clk(clk),
      .enable(perm_enable),
      .rst(rst),
      .in(state_reg),
      .state_out(perm_out),
      .valid(perm_valid)
  );


  // Finite state machine : two always blocks
  // combinational block
  always_comb begin
    // signal
    busy            = 1'b1;
    perm_enable     = 1'b0;
    done            = 1'b0;
    block_out_valid = 1'b0;
    next_state      = SC_IDLE;

    case (current_state)
      default: next_state = SC_IDLE;
      SC_IDLE: begin
        busy = 1'b0;
        if (start) next_state = SC_INIT;
      end

      SC_INIT: next_state = SC_WAIT_BLOCK_IN;

      SC_WAIT_BLOCK_IN: begin
        next_state = SC_WAIT_BLOCK_IN;
        if (block_in_ready) next_state = SC_ABSORB;
      end

      SC_ABSORB: next_state = SC_PERMUTE;

      SC_PERMUTE: begin
        next_state  = SC_PERMUTE;
        perm_enable = 1'b1;
        if (perm_valid) begin
          next_state = SC_WAIT_BLOCK_IN;
          if (last_block) next_state = SC_SQUEEZE;
        end
      end

      SC_SQUEEZE: begin
        block_out_valid = 1'b1;
        next_state = SC_DONE;  // normal case just squeeze once
        // matrix generation mode have to squeeze more than once
        if (matrix_gen) begin
          if (squeeze_count == 2) next_state = SC_DONE;
          else next_state = SC_PERMUTE;
        end
      end

      SC_DONE: begin
        done = 1'b1;
        busy = 1'b0;
        next_state = SC_IDLE;
      end
    endcase
  end


  // sequential block
  always_ff @(posedge clk) begin
    if (rst) begin
      current_state <= SC_IDLE;
      state_reg <= '0;
      block_out <= '0;
      squeeze_count <= 2'b0;
    end

    current_state <= next_state;
    unique case (current_state)
      SC_IDLE: ;

      SC_INIT: begin
        // clear  reg at the start of permutation
        state_reg <= '0;
        block_out <= '0;
        squeeze_count <= 2'b0;
      end

      SC_WAIT_BLOCK_IN: ;

      SC_ABSORB: begin
        // MAX_RATE_BYTE*8=1344 
        for (int k = 0; k < MAX_RATE_BYTES; k = k + 1) begin
          if (k < rate_bytes) begin
            state_reg[8*k+:8] <= state_reg[8*k+:8] ^ block_in[8*k+:8];
          end
        end
      end

      SC_PERMUTE: if (perm_valid) state_reg <= perm_out;

      SC_SQUEEZE: begin
        squeeze_count <= squeeze_count + 1;
        for (int k = 0; k < MAX_RATE_BYTES; k = k + 1) begin
          if (k < rate_bytes) begin
            block_out[8*k+:8] <= state_reg[8*k+:8];
          end
        end
      end

      SC_DONE: ;
    endcase
  end
endmodule
