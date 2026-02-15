module cooley_tukey(
    input clk,
    input start,
    input signed [15:0] a,
    input signed [15:0] b,
    input signed [15:0] zeta,
    output signed [15:0] out0,
    output signed [15:0] out1
);
  wire signed [15:0] t;

  fqmul mul (
      .clk(clk),
      .start(start),
      .a(zeta),
      .b(b),
      .r(t)
  );

  assign out0 = a + t;
  assign out1 = a - t;
endmodule
