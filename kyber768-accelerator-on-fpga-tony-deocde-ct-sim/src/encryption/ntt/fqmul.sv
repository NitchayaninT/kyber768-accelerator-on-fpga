`include "montgomery_reduce.sv"
module fqmul (
  input clk,
  input start,
  input signed [15:0] a,
  input signed [15:0] b,
  output signed [15:0] r
);

  reg signed [31:0] mul;
  reg [1:0] count;
  // cycle0 :start -> count = 0 and compute a*b
  // cycle1,2,3 : count = 0,1,2 : using 3 clks compute montgomery_reduce
  // when count <= 3 the fqmul finihsed and do nothing

  montgomery_reduce red(.a(mul), .r(r), .clk(clk), .count(count));
  always @(posedge clk) begin
    if (start) begin
      count <= 0;
      mul <= a*b;
    end
    else if(count < 3) begin
      count <= count+1;
    end
  end
endmodule

