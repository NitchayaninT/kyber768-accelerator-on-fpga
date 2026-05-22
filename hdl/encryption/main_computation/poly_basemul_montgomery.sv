// this design is base on KYBER reference

import params_pkg::*;
module poly_basemul_montgomery (
    input clk,
    input start,
    input [2*KYBER_POLY_WIDTH - 1:0] poly_a0,
    poly_a1,
    poly_b0,
    poly_b1,
    input signed [KYBER_POLY_WIDTH - 1:0] zeta_a,
    input signed [KYBER_POLY_WIDTH - 1:0] zeta_b,
    output signed [KYBER_POLY_WIDTH - 1:0] basemul0_r[2],
    basemul1_r[2],
    output valid
);
  // **************************************************
  // Declaration of basemul module
  // **************************************************
  wire basemul_start = start;
  wire signed [KYBER_POLY_WIDTH - 1:0] basemul0_a[2], basemul0_b[2];
  wire signed [KYBER_POLY_WIDTH - 1:0] basemul1_a[2], basemul1_b[2];
  wire signed [KYBER_POLY_WIDTH - 1:0] basemul_zeta[2];
  // these 2 variable just for readability
  assign basemul_zeta[0] = zeta_a;  // this is zeta[i]
  assign basemul_zeta[1] = zeta_b;  // this is -zeta[i]
  // get input from 2 ram_in
  // ram_in0 store a
  // ram_in1 store b
  assign basemul0_a[1]   = $signed(poly_a0[31:16]);
  assign basemul0_a[0]   = $signed(poly_a0[15:0]);
  assign basemul0_b[1]   = $signed(poly_b0[31:16]);
  assign basemul0_b[0]   = $signed(poly_b0[15:0]);

  assign basemul1_a[1]   = $signed(poly_a1[31:16]);
  assign basemul1_a[0]   = $signed(poly_a1[15:0]);
  assign basemul1_b[1]   = $signed(poly_b1[31:16]);
  assign basemul1_b[0]   = $signed(poly_b1[15:0]);

  basemul basemul0 (
      .clk(clk),
      .start(basemul_start),
      .a(basemul0_a),
      .b(basemul0_b),
      .zeta(basemul_zeta[0]),
      .r(basemul0_r),
      .valid(valid)
  );
  basemul basemul1 (
      .clk(clk),
      .start(basemul_start),
      .a(basemul1_a),
      .b(basemul1_b),
      .zeta(basemul_zeta[1]),
      .r(basemul1_r),
      .valid(valid)
  );
endmodule
