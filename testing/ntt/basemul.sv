`include "fqmul.sv"
module basemul(
  input signed [15:0] a[2],
  input signed [15:0] b[2],
  input signed [15:0] zeta,
  output signed [15:0] r[2]
  );

  wire signed [15:0] a1b1;
  wire signed [15:0] a1b1z;
  wire signed [15:0] a0b0;
  fqmul fqmul_a1_b1(.a(a[1]),.b(b[1]), .r(a1b1));   // r[0]  = fqmul(a[1], b[1]);
  fqmul fqmul_a1b1_z(.a(a1b1), .b(zeta), .r(a1b1z));// r[0]  = fqmul(r[0], zeta);
  fqmul fqmul_a0_b0(.a(a[0]), .b(b[0]), .r(a0b0)); //r[0] += fqmul(a[0], b[0]);
  assign r[0] = a0b0 + a1b1z;

  wire signed [15:0] a0b1;
  wire signed [15:0] a1b0;

  fqmul fqmul_a0_b1(.a(a[0]), .b(b[1]), .r(a0b1));
  fqmul fqmul_a1_b0(.a(a[1]), .b(b[0]), .r(a1b0));
  assign r[1] = a0b1 + a1b0;
endmodule
