import params_pkg::*;
module basemul (
    input clk,
    input start,
    input reset,
    input signed [KYBER_POLY_WIDTH - 1:0] a[2],
    input signed [KYBER_POLY_WIDTH - 1:0] b[2],
    input signed [KYBER_POLY_WIDTH - 1:0] zeta,
    output logic signed [KYBER_POLY_WIDTH - 1:0] r[2],
    output logic valid
);

  reg fqmul_enable;
  wand fqmul_valid;
  //reg signed [KYBER_POLY_WIDTH - 1:0] a1b1;
  reg signed [KYBER_POLY_WIDTH - 1:0] a_in[2];
  reg signed [KYBER_POLY_WIDTH - 1:0] b_in[2];
  wire signed [KYBER_POLY_WIDTH - 1:0] buf_out[2];
  genvar g;
  generate
    for (g = 0; g < 2; g++) begin : g_fqmul
      fqmul fqmul_uut (
          .clk(clk),
          .enable(fqmul_enable),
          .a(a_in[g]),
          .b(b_in[g]),
          .r(buf_out[g]),
          .valid(fqmul_valid)
      );
    end
  endgenerate

  //reg add;

  typedef enum {
    BASEMUL_IDLE,
    BASEMUL_FQMUL_0,
    BASEMUL_FQMUL_1,
    BASEMUL_FQMUL_2,
    BASEMUL_DONE
  } basemul_state_e;
  basemul_state_e current_state, next_state;

  always_comb begin
    next_state = BASEMUL_IDLE;
    valid = 0;
    //add = 0;
    case (current_state)
      BASEMUL_IDLE: begin
        if (start) begin
          next_state = BASEMUL_FQMUL_0;
        end
      end
      BASEMUL_FQMUL_0: begin
        if (fqmul_valid) begin
          next_state = BASEMUL_FQMUL_1;
          //add = 1;  // add the result for r[1] done in parallel with BASEMUL_FQMUL1
        end else next_state = BASEMUL_FQMUL_0;
      end
      BASEMUL_FQMUL_1: begin
        if (fqmul_valid) begin
          next_state = BASEMUL_FQMUL_2;
        end else next_state = BASEMUL_FQMUL_1;
      end
      BASEMUL_FQMUL_2: begin
        if (fqmul_valid) begin
          next_state = BASEMUL_DONE;
        end else next_state = BASEMUL_FQMUL_2;
      end
      BASEMUL_DONE: begin
        next_state = BASEMUL_IDLE;
        valid = 1;
      end

      default;
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      fqmul_enable <= 0;
      a_in[0] <= 0;
      b_in[0] <= 0;
      a_in[1] <= 0;
      b_in[1] <= 0;
    end else begin
      current_state <= next_state;
      case (current_state)
        BASEMUL_IDLE: begin
          if (start) begin
            a_in[0] <= a[0];
            b_in[0] <= b[1];
            a_in[1] <= a[1];
            b_in[1] <= b[0];
            fqmul_enable <= 1;
          end else fqmul_enable <= 0;
        end
        BASEMUL_FQMUL_0: begin
          fqmul_enable <= 0;
          if (fqmul_valid) begin
            a_in[0] <= a[0];
            b_in[0] <= b[0];
            a_in[1] <= a[1];
            b_in[1] <= b[1];
            r[1] <= buf_out[0] + buf_out[1];
            fqmul_enable <= 1;
          end
        end
        BASEMUL_FQMUL_1: begin
          fqmul_enable <= 0;
          if (fqmul_valid) begin
            a_in[1] <= buf_out[1];  // buf_out is a1b1
            b_in[1] <= zeta;
            fqmul_enable <= 1;
          end
        end
        BASEMUL_FQMUL_2: begin
          fqmul_enable <= 0;
          if (fqmul_valid) r[0] <= buf_out[0] + buf_out[1];
        end
        BASEMUL_DONE: ;
        default: ;
      endcase
    end
  end
endmodule
