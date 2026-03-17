// modify some of the bits of Lane 0 in a manner that depends on the round index ir
module iota (
    input [1599:0] state_in,
    input [4:0] ir,
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
        R = 8'b10000000;  // initialize R to 10000000
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

  assign A_out[0] = A_in[0] ^ RC64(ir);  // Append modified bits to original Lane 0
  for (j = 1; j < 25; j = j + 1) begin : g_aout
    assign A_out[j] = A_in[j];
  end

  // pack to state_out, len by len
  genvar j;
  generate
    for (j = 0; j < 25; j = j + 1) begin : packing
      assign state_out[j*64+:64] = A_out[j];
    end
  endgenerate
endmodule

