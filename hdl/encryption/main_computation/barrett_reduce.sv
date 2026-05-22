import params_pkg::*;

// barett_recude module perform barett reduction for input a;
// use 3 clock cycles

module barrett_reduce (
    input clk,
    input enable,
    input signed [KYBER_POLY_WIDTH - 1:0] a,
    output logic signed [KYBER_POLY_WIDTH - 1:0] r,
    output logic valid
);
  localparam logic signed [KYBER_POLY_WIDTH - 1:0] v = 20159;
  logic [1:0] count;
  logic signed [2*KYBER_POLY_WIDTH -1:0] t;

  always @(posedge clk) begin
    valid <= 0;  // default each cycle
    if (enable) begin
      t <= (v * a) >>> 26;
      count <= 0;
      valid <= 0;
    end else if (!valid && count != 3) begin
      count <= count + 1;
      case (count)
        0: t <= t * KYBER_Q;
        1: r <= KYBER_POLY_WIDTH'((2 * KYBER_POLY_WIDTH)'(a) - t);
        2: valid <= 1;
        default valid <= 0;
      endcase
    end
  end
endmodule
