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

module montgomery_reduce (
    input  signed [31:0] a,
    input clk,
    input [1:0] count,
    output reg signed [15:0] r
);
    localparam [15:0] q    = 16'd3329;
    localparam [15:0] qinv = 16'd62209; // -q^{-1} mod 2^16

    reg signed [31:0] t;
    reg signed [15:0] u;
    always @(posedge clk) begin
      case (count)
        0 : u <= (a * qinv) & 16'hffff;// 1clk;
        1 : t <= u * q; // 1clk
        2 : begin
          r <= (a - t) >>> 16;          // arithmetic shift
        end
        default: ;
      endcase
    end
endmodule
