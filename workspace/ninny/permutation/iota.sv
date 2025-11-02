//`include "params.vh"
// modify some of the bits of Lane 0 in a manner that depends on the round index ir
module iota (
    input  [63:0] state_in [0:24],
    input  [ 4:0] ir,
    output [63:0] state_out[0:24]
);
  // function to calculate round constant and return bit 0
  function rc_bit;
    input integer t;
    reg [7:0] R;
    reg R8;
    integer i;
    begin
      if (t % 255 == 0) begin
        rc_bit = 1'b1;
      end else begin
        R  = 8'b10000000;  // initialize R to 10000000
        R8 = 1;
        for (i = 1; i <= (t % 255); i = i + 1) begin : xor_r8
          R8 = R[7];  // store MSB which will be used to XOR R[4], R[5], R[6]
          R = {R[6:0], 1'b0};  // left shift R by 1 by inserting 0 at LSB
          R[0] = R[0] ^ R8;
          R[4] = R[4] ^ R8;
          R[5] = R[5] ^ R8;
          R[6] = R[6] ^ R8;
        end
        rc_bit = R[0];  // returns LSB of R
      end
    end
  endfunction

// lane repositioning. move 64-bit lanes to new (x,y) locations in the grid
module pi (
    input  [63:0] state_in[0:24],
    output [63:0] state_out[0:24]
);

  // reposition the lanes
  function [63:0] reposition;
    input integer x, y;  // lane no. is x+5*y. x= row, y=column
    input  [63:0] state_in[0:24];
    integer lane_modified;  // value from 0-24
    begin
      lane_modified = (((x+(3*y)) % 5)+(5*x)); // from A[(x+3y) mod 5, x, z] -> use x+5*y to get len number
      reposition = state_in[lane_modified];
    end
  endfunction

  // generating output
  genvar x, y;
  generate
    for (x = 0; x < 5; x = x + 1) begin : rows
      for (y = 0; y < 5; y = y + 1) begin : columns
        assign state_out[x+(5*y)] = reposition(x, y, state_in);
      end
    end
  endgenerate
endmodule
  // function to get the 64-bit round constant based on ir
  // formula = RC[2^j-1] = rc_bit(j+7ir)
  // j is from 0 to 6 from the definition in fips202
  // returns modified Lane 0 (64 bits)
  function [63:0] RC64;
    input integer ir;  // current round index
    integer j;
    reg [63:0] rc;
    begin
      rc = 64'h0;  // initialize all 64 bits to 0
      for (j = 0; j <= 6; j = j + 1) begin : loop_rc
        rc[(1<<j)-1] =
            rc_bit(j + 7 * ir);  // modify only bits 0,1,3,7,15,31,63 in lane 0 based on ir
        RC64 = rc;
      end
    end
  endfunction

  // generating output
  assign state_out[0] = state_in[0] ^ RC64(ir);  // Append modified bits to original Lane 0
  generate
    for (i = 1; i < 25; i = i + 1) begin : pass_through
      assign state_out[i] = state_in[i];
    end
  endgenerate
endmodule
