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
