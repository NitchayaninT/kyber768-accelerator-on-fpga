// rotate each 64-bit lane by a fixed offset
module rho (
    input  [1599:0] state_in,
    output [1599:0] state_out
);
  // Unpack state into lanes with 64 bits
  wire [63:0] A_in [0:24];
  wire [63:0] A_out[0:24];
  genvar i;
  generate
    for (i = 0; i < 25; i = i + 1) begin : unpacking
      assign A_in[i] = state_in[i*64+:64];  //assign 64 bits to each lane
    end
  endgenerate

  // calculate offset (in order to add to the bits within each lane)
  function integer cal_offset;  // return int (offset) after calculation
    input integer x, y;  // row, column
    integer offset[0:24];  // store offset of each lane 0..64
    begin
      offset[0]  = 0;
      offset[1]  = 1;
      offset[2]  = 62;
      offset[3]  = 28;
      offset[4]  = 27;
      offset[5]  = 36;
      offset[6]  = 44;
      offset[7]  = 6;
      offset[8]  = 55;
      offset[9]  = 20;
      offset[10] = 3;
      offset[11] = 10;
      offset[12] = 43;
      offset[13] = 25;
      offset[14] = 39;
      offset[15] = 41;
      offset[16] = 45;
      offset[17] = 15;
      offset[18] = 21;
      offset[19] = 8;
      offset[20] = 18;
      offset[21] = 2;
      offset[22] = 61;
      offset[23] = 26;
      offset[24] = 14;
      cal_offset = offset[x+(5*y)];  // calculate offset based on row & column position
    end
  endfunction

  // function rotate left
  // need whole lane and offset
  function [63:0] rol;  //rol returns lane (64 bits)
    input [63:0] lane;  //input whole lane
    input [5:0] offset;  // offset is represented as 6 bits because its from 0-64
    begin
      rol = lane << offset | lane >> (64 - offset);
      // bits moves towards MSB by offset (rol)
      // bits that are left out have to go to the front, so shift right to get the left out bits
      // then just XOR them to get the whole thing
    end
  endfunction

  // generating output
  genvar x, y;
  generate
    for (x = 0; x < 5; x = x + 1) begin : rows
      for (y = 0; y < 5; y = y + 1) begin : columns
        assign A_out[x+(5*y)] = rol(A_in[x+(5*y)], cal_offset(x, y));
      end
    end
  endgenerate

  // pack to state_out, len by len
  genvar j;
  generate
    for (j = 0; j < 25; j = j + 1) begin : packing
      assign state_out[j*64+:64] = A_out[j];
    end
  endgenerate
endmodule

