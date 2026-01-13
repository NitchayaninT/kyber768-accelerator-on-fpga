module fqmul (
  input clk,
  input signed [15:0] a,
  input signed [15:0] b,
  output signed [15:0] r
);

  reg signed [31:0] mul;
  always @(posedge clk) begin
    mul <= a * b; // 1clk
  end
  montgomery_reduce red(.a(mul), .r(r));
endmodule

module montgomery_reduce (
    input  signed [31:0] a,
    output signed [15:0] r
);
    localparam [15:0] Q    = 16'd3329;
    localparam [15:0] QINV = 16'd62209; // -q^{-1} mod 2^16

    wire signed [31:0] t;
    wire signed [15:0] u;
    wire signed [31:0] a_sub_t;

    assign u = (a * QINV) & 16'hFFFF;// 1clk;
    assign t = u * Q; // 1clk
    assign a_sub_t = a - t;
    assign r = a_sub_t >>> 16;          // arithmetic shift
endmodule
