// XOR each bit with a non-linear function of two other bits in its row
module chi (
    input  [63:0] state_in[0:24],
    output [63:0] state_out[0:24]
);

  // function to AND and XOR based on column number (lane % 5)
  // return CURRENT lane after XOR and AND
  function [63:0] and_xor;
    input [63:0] lane;  // current lane
    input [63:0] lane1;  // lane used to AND & XOR
    input [63:0] lane2;  // another lane used to AND & XOR
    //integer lane_no = (x*5)+y;
    begin
      and_xor = lane ^ (~lane1 & lane2);
    end
  endfunction

  // generating output
  genvar x, y;
  generate
    for (x = 0; x < 5; x = x + 1) begin : rows
      for (y = 0; y < 5; y = y + 1) begin : columns
        // input current lane, lane1, and lane2 
        localparam integer lane_no = x + (5 * y);
        localparam integer lane1_no = (y * 5) + (lane_no + 1) % 5;
        localparam integer lane2_no = (y * 5) + (lane_no + 2) % 5;
        assign A_out[lane_no] = and_xor(state_in[lane_no], state_in[lane1_no], state_in[lane2_no]);
      end
    end
  endgenerate
endmodule

