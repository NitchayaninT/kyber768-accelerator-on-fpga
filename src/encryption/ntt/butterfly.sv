// **************************************************
// butterfly module has 2 modes
// 1. cooley tukey butterfly : for NTT
// 2. gentleman sande butterfly : for INV_NTT
// note: barrett reduce a step are done outside this module
// **************************************************

import enums_pkg::*;
import params_pkg::*;

module butterfly (
    input clk,
    input enable,
    input ntt_mode_e mode,
    input fqmul_zeta_inv127,
    input signed [KYBER_POLY_WIDTH - 1:0] a,
    input signed [KYBER_POLY_WIDTH - 1:0] b,
    input signed [KYBER_POLY_WIDTH - 1:0] zeta,
    output signed [KYBER_POLY_WIDTH - 1:0] out0,
    output signed [KYBER_POLY_WIDTH - 1:0] out1,
    output logic valid
);

  logic signed [KYBER_POLY_WIDTH - 1:0] fqmul_ina;
  logic signed [KYBER_POLY_WIDTH - 1:0] fqmul_inb;
  logic signed [KYBER_POLY_WIDTH - 1:0] fqmul_out;
  logic fqmul_enable;
  logic fqmul_valid;
  logic [1:0] fqmul_count; // use for the last inv_ntt_fqmul step we need to do fqmul 3 times instead of once

  fqmul mul (
      .clk(clk),
      .enable(fqmul_enable),
      .a(fqmul_ina),
      .b(fqmul_inb),
      .r(fqmul_out),
      .valid(fqmul_valid)
  );

  logic signed [KYBER_POLY_WIDTH - 1:0] zeta_inv127 = 16'h05a1;
  logic signed [KYBER_POLY_WIDTH - 1:0] bufout0;
  logic signed [KYBER_POLY_WIDTH - 1:0] bufout1;

  assign out0 = (fqmul_zeta_inv127) ? bufout0 : (mode == NTT) ? a + fqmul_out : a + b;
  assign out1 = (fqmul_zeta_inv127) ? bufout1 : (mode == NTT) ? a - fqmul_out : fqmul_out;

  always_comb begin
    fqmul_ina = 0;
    fqmul_inb = 0;
    if (!fqmul_zeta_inv127) begin
      fqmul_ina = zeta;
      fqmul_inb = (mode == NTT) ? b : a - b;
    end else begin
      // if inv_ntt_last_stage 
      fqmul_ina = (fqmul_count == 0) ? a : b;
      fqmul_inb = zeta_inv127;
    end
  end


  always_ff @(posedge clk) begin
    valid <= 0;
    fqmul_enable <= 0;
    if (enable) begin
      fqmul_enable <= 1;
      fqmul_count  <= 0;
    end
    if (!fqmul_zeta_inv127) begin
      valid <= fqmul_valid;
      // in normal mode (NOT the last step of INV_NTT)
      // actually do nothing here in normal mode it just combinatinal output
    end else begin
      valid <= fqmul_valid && (fqmul_count == 1);
      if (fqmul_valid) begin
        unique case (fqmul_count)
          0: begin
            fqmul_count <= fqmul_count + 1;
            bufout0 <= fqmul_out;
            fqmul_enable <= 1;
          end
          1: begin
            bufout1 <= fqmul_out;
            fqmul_count <= fqmul_count + 1;
          end
          2: ;
        endcase
      end
    end
  end
endmodule
