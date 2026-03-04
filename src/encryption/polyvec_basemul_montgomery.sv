import params_pkg::*;

// READ DATA from 3 rams at the same time
// each ram we read from 2 ports a = lower addr, b = higher addr
// e.g. first time index = 0; a = 0, b = 1
// since MAIN COMPUTE's RAM is 32 bits we actually fecth 4 opperands per 
module polyvec_basemul_montgomery (
    // Control Signal
    input clk,
    input reset,
    input enable,
    output logic valid,

    // Signal For ROM zeta
    input signed [KYBER_POLY_WIDTH - 1:0] zeta,
    output logic [6:0] rom_zeta_addr,

    // Signal for ram input
    input [2*KYBER_POLY_WIDTH - 1:0] ram0_read_data_a[3],  // ram_0 store a_t or t_vec
    input [2*KYBER_POLY_WIDTH - 1:0] ram0_read_data_b[3],
    input [2*KYBER_POLY_WIDTH - 1:0] ram1_read_data_a[3],  // ram_1 store r
    input [2*KYBER_POLY_WIDTH - 1:0] ram1_read_data_b[3],

    output [2*KYBER_POLY_WIDTH - 1:0] ram_write_data_a,  // store basemul r0
    output [2*KYBER_POLY_WIDTH - 1:0] ram_write_data_b,  // store basemul r1
    output logic ram_we,
    output logic ram_en,
    output logic [6:0] ram_addra,
    output logic [6:0] ram_addrb
    // Signal for ram out
);

  // **************************************************
  // 3 parallel poly_basemul_montgomery modules
  // computing 3 polynominal pointwise multiplications in parallel
  // **************************************************
  logic signed [KYBER_POLY_WIDTH - 1 : 0] basemul0_r[3][2], basemul1_r[3][2];
  wand basemul_valid;  // all of the base
  logic basemul_start;
  logic signed [KYBER_POLY_WIDTH - 1:0] zeta_2s;
  assign zeta_2s = -zeta;

  genvar g;
  generate
    for (g = 0; g < 3; g++) begin : g_poly_basemul_montgomery
      poly_basemul_montgomery pbm (
          .clk(clk),
          .start(basemul_start),
          .poly_a0(ram0_read_data_a[g]),
          .poly_b0(ram1_read_data_a[g]),
          .poly_a1(ram0_read_data_b[g]),
          .poly_b1(ram1_read_data_b[g]),
          .zeta_a(zeta),
          .zeta_b(zeta_2s),
          .basemul0_r(basemul0_r[g]),
          .basemul1_r(basemul1_r[g]),
          .valid(basemul_valid)
      );
    end
  endgenerate


  // **************************************************
  // Barett reductions modules
  // **************************************************
  // get output from the poly_basemul_mongomery
  // add them together, then apply barret reduction
  logic signed [KYBER_POLY_WIDTH -1:0] sum_basemul0_r[2];
  logic signed [KYBER_POLY_WIDTH -1:0] sum_basemul1_r[2];
  assign sum_basemul0_r[1] = basemul0_r[0][1] + basemul0_r[1][1] + basemul0_r[2][1]; //sum_basemul0_rh
  assign sum_basemul0_r[0] = basemul0_r[0][0] + basemul0_r[1][0] + basemul0_r[2][0]; //sum_basemul0_rl
  assign sum_basemul1_r[1] = basemul1_r[0][1] + basemul1_r[1][1] + basemul1_r[2][1]; //sum_basemul1_rh
  assign sum_basemul1_r[0] = basemul1_r[0][0] + basemul1_r[1][0] + basemul1_r[2][0]; //sum_basemul1_rl

  logic signed [KYBER_POLY_WIDTH - 1 : 0] barrett_r0[2];
  logic signed [KYBER_POLY_WIDTH - 1 : 0] barrett_r1[2];
  // Pack results to 32 bits for ram
  assign ram_write_data_a = {barrett_r0[1], barrett_r0[0]};
  assign ram_write_data_b = {barrett_r1[1], barrett_r1[0]};

  wand  barrett_valid;
  logic barrett_enable;
  generate
    for (g = 0; g < 2; g++) begin : g_barrett
      barrett_reduce barrett_red_sum_b0 (
          .clk   (clk),
          .enable(barrett_enable),
          .a     (sum_basemul0_r[g]),
          .r     (barrett_r0[g]),
          .valid (barrett_valid)
      );
      barrett_reduce barrett_red_sum_b1 (
          .clk   (clk),
          .enable(barrett_enable),
          .a     (sum_basemul1_r[g]),
          .r     (barrett_r1[g]),
          .valid (barrett_valid)
      );
    end
  endgenerate
  // **************************************************
  // control signal & Main behavior
  // **************************************************

  logic [6:0] index;  // in 2 basemul design64 times

  assign last_index = (index == 63);


  typedef enum {
    PVBM_IDLE,
    PVBM_READ_INPUT,
    PVBM_COMPUTE_BASEMUL,
    PVBM_BARRETT_REDUCE,
    PVBM_WRITE_OUTPUT,
    PVBM_NEXT_INDEX,
    PVBM_DONE
  } polyvec_basemul_montgomery_state_e;

  polyvec_basemul_montgomery_state_e current_state, next_state;

  assign ram_addra = index * 2;
  assign ram_addrb = (index * 2) + 1;

  always_comb begin
    next_state = PVBM_IDLE;
    ram_en = 0;
    ram_we = 0;
    valid = 0;

    basemul_start = 0;
    // BARRETT
    barrett_enable = 0;

    case (current_state)
      PVBM_IDLE: begin
        if (enable) begin
          next_state = PVBM_READ_INPUT;
          ram_en = 1;
        end
      end

      PVBM_READ_INPUT: begin
        next_state = PVBM_COMPUTE_BASEMUL;
        basemul_start = 1;
      end

      PVBM_COMPUTE_BASEMUL: begin
        if (basemul_valid) begin
          barrett_enable = 1;
          next_state = PVBM_BARRETT_REDUCE;
        end else next_state = PVBM_COMPUTE_BASEMUL;
      end

      PVBM_BARRETT_REDUCE: begin
        if (barrett_valid) begin
          next_state = PVBM_WRITE_OUTPUT;
          ram_en = 1;
          ram_we = 1;
        end else next_state = PVBM_BARRETT_REDUCE;
      end
      PVBM_WRITE_OUTPUT: begin
        if (last_index) next_state = PVBM_DONE;
        else next_state = PVBM_NEXT_INDEX;
      end
      PVBM_NEXT_INDEX: begin
        next_state = PVBM_READ_INPUT;
        ram_en = 1;
      end
      PVBM_DONE: begin
        valid = 1;
        next_state = PVBM_IDLE;
      end
      default: ;
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      index <= 0;
      rom_zeta_addr <= 64;
    end else begin
      current_state = next_state;
      case (current_state)
        PVBM_IDLE: begin
          index <= 0;
          rom_zeta_addr <= 64;
        end
        PVBM_READ_INPUT: ;
        PVBM_COMPUTE_BASEMUL: ;
        PVBM_BARRETT_REDUCE: ;
        PVBM_WRITE_OUTPUT: ;
        PVBM_NEXT_INDEX: begin
          index <= index + 1;
          rom_zeta_addr <= rom_zeta_addr + 1;
        end
        PVBM_DONE: ;

        default: ;
      endcase

    end
  end
endmodule
