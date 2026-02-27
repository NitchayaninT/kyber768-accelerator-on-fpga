// **************************************************
// NTT module has 2 modes
// 1. NTT
// 2. INV_NTT
// **************************************************

import params_pkg::*;
import enums_pkg::*;

`define HIGHER_BITS 31:16
`define LOWER_BITS 15:0
typedef enum {
  NTT_IDLE,
  NTT_READ_INPUT,  // read 4 times to get input variable
  NTT_COMPUTE,
  NTT_WRITE_OUTPUT,
  NTT_BARRETT_REDUCE,
  NTT_NEXT_BLOCK,
  NTT_NEXT_STAGE,

  // we can use the same READ_INPUT, WRITE_OUTPUT 
  INV_NTT_BARRETT_REDUCE,
  INV_NTT_COMPUTE,
  INV_NTT_WRITE_OUTPUT,
  INV_NTT_NEXT_BLOCK,
  INV_NTT_NEXT_STAGE,

  NTT_DONE
} ntt_state_e;

typedef enum {
  STRIDE_NORMAL,
  STRIDE_4,
  STRIDE_2
} stride_e;

module ntt (
    input clk,
    input reset,
    input enable,
    input ntt_mode_e mode,
    output reg valid,

    // input/output RAM signal
    input [2 * KYBER_POLY_WIDTH - 1:0] ram_read_data_a,
    input [2 * KYBER_POLY_WIDTH - 1:0] ram_read_data_b,
    output logic [2 * KYBER_POLY_WIDTH - 1:0] ram_write_data_a,
    output logic [2 * KYBER_POLY_WIDTH - 1:0] ram_write_data_b,
    output logic [MC_RAM_ADDR_BITS - 1 : 0] ram_addra,
    ram_addrb,
    output logic ram_en,
    output logic ram_we,

    // Zeta rom signal
    input signed [KYBER_POLY_WIDTH - 1 : 0] zeta_a,
    input signed [KYBER_POLY_WIDTH - 1 : 0] zeta_b,
    output [MC_ZETA_ADDR_BITS - 1 : 0] rom_zeta_addra,
    rom_zeta_addrb,

    // Zeta_inv rom signal
    input signed [KYBER_POLY_WIDTH - 1 : 0] zeta_inv_a,
    input signed [KYBER_POLY_WIDTH - 1 : 0] zeta_inv_b,
    output [MC_ZETA_ADDR_BITS - 1:0] rom_zeta_inv_addra,
    output [MC_ZETA_ADDR_BITS - 1:0] rom_zeta_inv_addrb
);

  // Declare 8 parallel Cooley tukey modules
  logic signed [KYBER_POLY_WIDTH - 1:0] butterfly_out0[8], butterfly_out1[8];
  logic signed [KYBER_POLY_WIDTH - 1 : 0] butterfly_a[8], butterfly_b[8];
  // worst case 4 zetas is used in one butterfly_set
  logic signed [KYBER_POLY_WIDTH - 1 : 0] butterfly_zeta[4];

  logic [4:0] butterly_set;
  logic butterfly_start;
  wand butterfly_valid;

  logic barrett_reduce_start;
  logic signed [KYBER_POLY_WIDTH - 1:0] barrett_reduce_out0[8], barrett_reduce_out1[8];
  wand  barrett_reduce_valid;
  logic barrett_reduce_done;
  assign barrett_reduce_done = barrett_reduce_valid;

  genvar g;
  generate
    for (g = 0; g < 8; g++) begin : g_butterfly
      butterfly clt (
          .clk(clk),
          .enable(butterfly_start),
          .mode(mode),
          .a(butterfly_a[g]),
          .b(butterfly_b[g]),
          .zeta(butterfly_zeta[g/2]),
          //output
          .out0(butterfly_out0[g]),
          .out1(butterfly_out1[g]),
          .valid(butterfly_valid)
      );

      barrett_reduce barrett_reduce_0 (
          .clk  (clk),
          .start(barrett_reduce_start),
          .a    (butterfly_out0[g]),
          .r    (barrett_reduce_out0[g]),
          .valid(barrett_reduce_valid)
      );

      barrett_reduce barett_reduce_1 (
          .clk  (clk),
          .start(barrett_reduce_start),
          .a    (butterfly_out1[g]),
          .r    (barrett_reduce_out1[g]),
          .valid(barrett_reduce_valid)
      );
    end
  endgenerate



  logic [7:0] start, len, j;
  logic [6:0] k;
  logic [2:0] stage;
  ntt_state_e current_state, next_state;

  stride_e stride;
  //assign stride = (stage < 5) ? STRIDE_NORMAL : (stage == 5) ? STRIDE_4 : STRIDE_2;
  assign stride = (mode == NTT)? ((stage < 5) ? STRIDE_NORMAL : (stage == 5) ? STRIDE_4 : STRIDE_2):
    (stage == 0)? STRIDE_2 : (stage == 1)? STRIDE_4 : STRIDE_NORMAL; // inv_ntt mode

  logic compute_done;
  assign compute_done = butterfly_valid;

  logic [2:0] compute_count;
  assign len = (mode == NTT) ? 8'd128 >> stage : 8'd2 << stage;

  // **************************************************
  // READ Input logic
  // **************************************************
  // in READ_INPUT state we need to set o_ram_addr_low and o_ram_addr_high
  // start from the j(current index) + read_input_count : 8 coeff per round
  wire signed [KYBER_POLY_WIDTH - 1:0] ram_data_ina_slice[2];
  wire signed [KYBER_POLY_WIDTH - 1:0] ram_data_inb_slice[2];
  assign ram_data_ina_slice[0] = $signed(ram_read_data_a[`LOWER_BITS]);
  assign ram_data_ina_slice[1] = $signed(ram_read_data_a[`HIGHER_BITS]);
  assign ram_data_inb_slice[0] = $signed(ram_read_data_b[`LOWER_BITS]);
  assign ram_data_inb_slice[1] = $signed(ram_read_data_b[`HIGHER_BITS]);

  logic ram_rw_done;
  logic [2:0] ram_rw_count, ram_rw_count_delay;
  // need to add delay here: read_input_count == 0, set ram_addr but
  // ram_read_data_a,ram_read_data_b only arrive one cycle later
  // so the first 2 bits are load at read_input_count = 0;
  // read_input_count_delay = 1;
  always_ff @(posedge clk) ram_rw_count_delay <= ram_rw_count;

  assign rom_zeta_addra = k;
  assign rom_zeta_addrb = rom_zeta_addra + 1;

  // **************************************************
  // Write Output logic: move to always_comb block
  // **************************************************
  // write output need to choose if last stage or not
  // last stage get output from barrett reduce
  // else get output from butterfly

  // State Transition logics
  logic block_done;
  assign block_done = (j + 8 >= start + len);

  logic stage_done;
  assign stage_done = (butterly_set == 16);

  logic last_stage;
  assign last_stage = (stage == 6);

  always_comb begin
    ram_addra = 0;
    ram_addrb = 0;
    case (stride)
      STRIDE_NORMAL: begin
        ram_addra = 7'(j >> 1) + 7'(ram_rw_count);
        ram_addrb = 7'((j + len) >> 1) + 7'(ram_rw_count);
      end
      STRIDE_4: begin
        if (ram_rw_count < 2) begin
          ram_addra = 7'(j >> 1) + 7'(ram_rw_count);
          ram_addrb = 7'((j + len) >> 1) + 7'(ram_rw_count);
        end else begin
          ram_addra = 7'((j + len) >> 1) + 7'(ram_rw_count);
          ram_addrb = 7'((j + 2 * len) >> 1) + 7'(ram_rw_count);
        end
      end
      STRIDE_2: begin
        ram_addra = 7'(j >> 1) + 7'(2 * ram_rw_count);
        ram_addrb = 7'(j >> 1) + 7'(2 * ram_rw_count) + 1;
      end
      default;
    endcase
  end

  always_comb begin
    // default state
    next_state = NTT_IDLE;
    valid = 0;
    ram_en = 0;
    ram_we = 0;
    butterfly_start = 0;
    barrett_reduce_start = 0;
    ram_rw_done = 0;
    ram_write_data_a = '0;
    ram_write_data_b = '0;
    case (current_state)
      NTT_IDLE: begin
        if (enable) begin
          next_state = NTT_READ_INPUT;
        end
      end

      NTT_READ_INPUT: begin
        ram_rw_done = ram_rw_count == 4;
        if (ram_rw_done) next_state = NTT_COMPUTE;
        else begin
          next_state = NTT_READ_INPUT;
          ram_en = 1;
        end
      end

      NTT_COMPUTE: begin
        if (compute_count == 0) butterfly_start = 1;
        if (compute_done) begin
          // only reduce at the last stage
          if (last_stage) begin
            next_state = NTT_BARRETT_REDUCE;
            barrett_reduce_start = 1;
            // in normal stage NTT mode don't need to reduce
          end else next_state = NTT_WRITE_OUTPUT;
        end else next_state = NTT_COMPUTE;
      end

      NTT_BARRETT_REDUCE: begin
        if (barrett_reduce_done) next_state = NTT_WRITE_OUTPUT;
        else next_state = NTT_BARRETT_REDUCE;
      end

      NTT_WRITE_OUTPUT: begin
        ram_rw_done = ram_rw_count == 4;
        if (last_stage) begin
          if (ram_rw_done) next_state = NTT_NEXT_BLOCK;
          else begin
            ram_write_data_a = {
              barrett_reduce_out0[2*ram_rw_count+1], barrett_reduce_out0[2*ram_rw_count]
            };
            ram_write_data_b = {
              barrett_reduce_out1[2*ram_rw_count+1], barrett_reduce_out1[2*ram_rw_count]
            };
            ram_en = 1;
            ram_we = 1;
            next_state = NTT_WRITE_OUTPUT;
          end
        end else begin
          if (ram_rw_done) begin
            if (block_done) next_state = NTT_NEXT_BLOCK;
            else next_state = NTT_READ_INPUT;
          end else begin
            ram_en = 1;
            ram_we = 1;
            ram_write_data_a = {butterfly_out0[2*ram_rw_count+1], butterfly_out0[2*ram_rw_count]};
            ram_write_data_b = {butterfly_out1[2*ram_rw_count+1], butterfly_out1[2*ram_rw_count]};
            next_state = NTT_WRITE_OUTPUT;
          end
        end
      end

      NTT_NEXT_BLOCK: begin
        if (stage_done) begin
          if (last_stage) next_state = NTT_DONE;
          else next_state = NTT_NEXT_STAGE;
        end else next_state = NTT_READ_INPUT;
      end

      NTT_NEXT_STAGE: next_state = NTT_READ_INPUT;

      NTT_DONE: begin
        valid = 1;
        next_state = NTT_IDLE;
      end

      default: next_state = NTT_IDLE;
    endcase
  end

  task clear_clt;
    for (int i = 0; i < 8; i++) begin
      butterfly_a[i] <= 0;
      butterfly_b[i] <= 0;
    end
  endtask
  // Sequential behavior
  task reset_reg;
    ram_rw_count <= 0;
    compute_count <= 0;
    start <= 0;
    butterly_set <= 0;
    j <= 0;
  endtask

  always_ff @(posedge clk) begin
    if (reset) begin
      current_state <= NTT_IDLE;
      stage <= 0;
      clear_clt();
      k <= 1;
      reset_reg();
    end else begin
      current_state <= next_state;
      case (current_state)
        NTT_IDLE: begin
          if (mode == NTT) k <= 1;
          else k = 0;
          stage <= 0;
          clear_clt();
          reset_reg();
        end

        NTT_READ_INPUT: begin
          if (!ram_rw_done) ram_rw_count <= ram_rw_count + 1;
          else ram_rw_count <= 0;
          case (stride)
            STRIDE_NORMAL: begin
              // First cycle we set ram addr and we need to wait 1 cycle
              if (ram_rw_count != 0) begin
                butterfly_a[2*ram_rw_count_delay] <= ram_data_ina_slice[0];
                butterfly_a[2*ram_rw_count_delay+1] <= ram_data_ina_slice[1];
                butterfly_b[2*ram_rw_count_delay] <= ram_data_inb_slice[0];
                butterfly_b[2*ram_rw_count_delay+1] <= ram_data_inb_slice[1];
                butterfly_zeta[0] <= zeta_a;
                butterfly_zeta[1] <= zeta_a;
                butterfly_zeta[2] <= zeta_a;
                butterfly_zeta[3] <= zeta_a;
              end
            end

            STRIDE_4: begin
              if (ram_rw_count != 0) begin
                butterfly_a[2*ram_rw_count_delay] <= ram_data_ina_slice[0];
                butterfly_a[2*ram_rw_count_delay+1] <= ram_data_ina_slice[1];
                butterfly_b[2*ram_rw_count_delay] <= ram_data_inb_slice[0];
                butterfly_b[2*ram_rw_count_delay+1] <= ram_data_inb_slice[1];
                butterfly_zeta[0] <= zeta_a;
                butterfly_zeta[1] <= zeta_a;
                butterfly_zeta[2] <= zeta_b;
                butterfly_zeta[3] <= zeta_b;
              end
            end

            STRIDE_2: begin
              if (ram_rw_count != 0) begin
                butterfly_a[2*ram_rw_count_delay]   <= ram_data_ina_slice[0];
                butterfly_a[2*ram_rw_count_delay+1] <= ram_data_ina_slice[1];
                butterfly_b[2*ram_rw_count_delay]   <= ram_data_inb_slice[0];
                butterfly_b[2*ram_rw_count_delay+1] <= ram_data_inb_slice[1];
              end
              if (ram_rw_count == 1) begin
                butterfly_zeta[0] <= zeta_a;
                butterfly_zeta[1] <= zeta_b;
                k <= k + 2;
              end else if (ram_rw_count == 3) begin
                butterfly_zeta[2] <= zeta_a;
                butterfly_zeta[3] <= zeta_b;
              end
            end
            default;
          endcase
        end

        NTT_COMPUTE: begin
          compute_count <= compute_count + 1;
        end

        NTT_BARRETT_REDUCE: begin
        end

        NTT_WRITE_OUTPUT: begin
          compute_count <= 0;
          if (!ram_rw_done) ram_rw_count <= ram_rw_count + 1;
          else begin
            j <= j + 8;
            butterly_set <= butterly_set + 1;
            ram_rw_count <= 0;
          end
        end

        NTT_NEXT_BLOCK: begin
          case (stride)
            STRIDE_NORMAL: begin
              k <= k + 1;
              j <= j + len;  // j = start;
              start <= j + len;
            end
            STRIDE_4: begin
              k <= k + 2;
              j <= j + (len << 1);
              start <= j + (len << 1);
            end
            STRIDE_2: begin
              k <= k + 2;
              j <= j + (len << 2);
              start <= j + (len << 2);
            end
            default;
          endcase
        end
        NTT_NEXT_STAGE: begin
          reset_reg();
          stage <= stage + 1;
        end
        default: ;
      endcase
    end
  end

endmodule
