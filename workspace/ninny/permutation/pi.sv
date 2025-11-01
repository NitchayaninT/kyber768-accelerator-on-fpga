// lane repositioning. move 64-bit lanes to new (x,y) locations in the grid
module pi (
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

  // reposition the lanes
  function [63:0] reposition;
    input integer x, y;  // lane no. is x+5*y. x= row, y=column
    integer lane_modified;  // value from 0-24
    begin
      lane_modified = (((x+(3*y)) % 5)+(5*x)); // from A[(x+3y) mod 5, x, z] -> use x+5*y to get len number
      reposition = A_in[lane_modified];
    end
  endfunction

  // generating output
  genvar x, y;
  generate
    for (x = 0; x < 5; x = x + 1) begin : rows
      for (y = 0; y < 5; y = y + 1) begin : columns
        assign A_out[x+(5*y)] = reposition(x, y);
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

