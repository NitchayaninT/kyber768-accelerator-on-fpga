`timescale 1ns / 1ps
`include "params.vh"

module expand_small (
    input [`KYBER_SPOLY_WIDTH - 1 : 0] in,
    output reg [`KYBER_R_WIDTH - 1 : 0] out
);

  always_comb begin
    if (in == 3'b111) out = 12'd3328;  // -1
    else if (in == 3'b110) out = 12'd3327;  // -2
    else out = in;  // 0, 1, 2
  end
endmodule
