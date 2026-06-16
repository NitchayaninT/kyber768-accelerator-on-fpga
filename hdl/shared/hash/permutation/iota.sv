`timescale 1ns/1ps

// modify some of the bits of Lane 0 in a manner that depends on the round index ir
module iota (
    input  [1599:0] state_in,
    input  [4:0]    ir, // 0..23
    output [1599:0] state_out
);
  // Unpack
  wire [63:0] A_in [0:24];
  wire [63:0] A_out[0:24];

  genvar j;
  generate
    for (j = 0; j < 25; j = j + 1) begin : unpacking
      assign A_in[j] = state_in[j*64+:64];
    end
  endgenerate

  // 64-bit round constants (canonical, little-endian lane bit positions)
  function [63:0] rc64;
    input int r;
    begin
      case (r)
        0: rc64 = 64'h0000000000000001;
        1: rc64 = 64'h0000000000008082;
        2: rc64 = 64'h800000000000808A;
        3: rc64 = 64'h8000000080008000;
        4: rc64 = 64'h000000000000808B;
        5: rc64 = 64'h0000000080000001;
        6: rc64 = 64'h8000000080008081;
        7: rc64 = 64'h8000000000008009;
        8: rc64 = 64'h000000000000008A;
        9: rc64 = 64'h0000000000000088;
        10: rc64 = 64'h0000000080008009;
        11: rc64 = 64'h000000008000000A;
        12: rc64 = 64'h000000008000808B;
        13: rc64 = 64'h800000000000008B;
        14: rc64 = 64'h8000000000008089;
        15: rc64 = 64'h8000000000008003;
        16: rc64 = 64'h8000000000008002;
        17: rc64 = 64'h8000000000000080;
        18: rc64 = 64'h000000000000800A;
        19: rc64 = 64'h800000008000000A;
        20: rc64 = 64'h8000000080008081;
        21: rc64 = 64'h8000000000008080;
        22: rc64 = 64'h0000000080000001;
        23: rc64 = 64'h8000000080008008;
        default: rc64 = 64'h0;
      endcase
    end
  endfunction

  // XOR RC into lane (0,0). 
  assign A_out[0] = A_in[0] ^ rc64(ir);

  // pass-through lanes 1..24
  genvar k;
  generate
    for (k = 1; k < 25; k = k + 1) begin : loop_aout
      assign A_out[k] = A_in[k];
    end
  endgenerate

  // Repack
  genvar i;
  generate
    for (i = 0; i < 25; i = i + 1) begin : packing
      assign state_out[i*64+:64] = A_out[i];
    end
  endgenerate
endmodule

