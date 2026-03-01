module montgomery_reduce (
    input signed [31:0] a,
    input clk,
    input [2:0] count,
    output logic signed [15:0] r
);
  localparam signed [15:0] q = 16'd3329;
  localparam signed [31:0] qinv = 31'd62209;  // -q^{-1} mod 2^16

  logic signed [31:0] t;
  logic signed [15:0] u;
  always @(posedge clk) begin
    case (count)
      0:       u <= 16'(a * qinv);  // 1clk;
      1:       t <= u * q;  // 1clk
      2: begin
        r <= 16'((a - t) >>> 16);  // arithmetic shift
      end
      default: ;
    endcase
  end
endmodule
