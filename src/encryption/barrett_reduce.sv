`include "params.vh"
module barrett_reduce (
    input clk,
    input start,
    input signed [`KYBER_POLY_WIDTH - 1:0] a,
    output reg signed [`KYBER_POLY_WIDTH - 1:0] r
);
  localparam signed v = 20159;
  reg [1:0] count;
  reg valid;
  reg signed [2*`KYBER_POLY_WIDTH -1:0] t;

  always @(posedge clk) begin
    if (start) begin
      t <= (v * a) >>> 26;
      count <= 0;
      valid <= 0;
    end else if (!valid) begin
      count <= count + 1;
      case (count)
        0: t <= t * `KYBER_Q;
        1: r <= a - t;
        default valid <= 1;
      endcase
    end
  end
endmodule
