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
    input signed [KYBER_POLY_WIDTH - 1:0] a,
    input signed [KYBER_POLY_WIDTH - 1:0] b,
    input signed [KYBER_POLY_WIDTH - 1:0] zeta,
    output signed [KYBER_POLY_WIDTH - 1:0] out0,
    output signed [KYBER_POLY_WIDTH - 1:0] out1,
    output valid
);
  logic signed [KYBER_POLY_WIDTH - 1:0] t;

  fqmul mul (
      .clk(clk),
      .enable(enable),
      .a(zeta),
      .b((mode == NTT) ? b : a - b),
      .r(t),
      .valid(valid)
  );

  assign out0 = (mode == NTT) ? a + t : a + b;
  assign out1 = (mode == NTT) ? a - t : t;
endmodule
