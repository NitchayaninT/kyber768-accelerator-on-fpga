`timescale 1ns / 1ps
module shake (
    input clk,
    input enable,
    input rst,
    input [255:0] in,
    output [1599:0] state_out,
    output reg valid
);

  reg [4:0] round;
  reg [1599:0] state_buffer;
  wire [1599:0] theta_out;
  wire [1599:0] rho_out;
  wire [1599:0] pi_out;
  wire [1599:0] chi_out;
  wire [1599:0] iota_out;

  theta theta_uut (
      .state_in (state_buffer),
      .state_out(theta_out)
  );

  rho rho_uut (
      .state_in (theta_out),
      .state_out(rho_out)
  );

  pi pi_uut (
      .state_in (rho_out),
      .state_out(pi_out)
  );
  chi chi_uut (
      .state_in (pi_out),
      .state_out(chi_out)
  );

  iota iota_uut (
      .state_in(chi_out),
      .state_out(iota_out),
      .ir(round)
  );

  assign state_out = state_buffer;
  always @(posedge clk) begin
    if (rst) begin
      round <= 5'h00;
      valid <= 0;
      state_buffer <= 1600'h0;  // ← Initialize to avoid X's
    end else if (enable && !valid) begin
      if (round == 5'h00) begin
        state_buffer <= {1344'h0, in};  // Load input
        round <= round + 1;
      end else if (round <= 24) begin  // ← Rounds 1-24 (24 Keccak rounds)
        state_buffer <= iota_out;
        round <= round + 1;
        if (round == 24) begin  // ← After 24th round completes
          valid <= 1;
        end
      end
    end
  end
endmodule

// input state has 1600 bits
module theta (
    input  [1599:0] state_in,
    output [1599:0] state_out
    //output [63:0] d_test[0:4]
);
  // Unpack state into lanes with 64 bits
  wire [63:0] A_in[0:24];  // Array A_in is stored as 25 lanes, 64 bits per lane
  genvar i;
  generate
    for (i = 0; i < 25; i = i + 1) begin : unpacking
      assign A_in[i] = state_in[i*64+:64];  //assign 64 bits to each lane
    end
  endgenerate

  // STEP 1 : Theta
  // Get parity of 2 neighbor columns and then XOR with the current column
  // more info in guide.txt
  // C is to store parity of bits within column (each column stores 64 bits of parities)
  // D is to store parity of bits from 2 neighboring columns (stores in 64 bits form, each bit has different neighbor parity)
  wire [63:0] C[0:4], D[0:4];

  // just for debug signal uncomment for simluation
  /*
  for (i = 0; i < 5; i = i + 1) begin : g_debug
    assign d_test[i] = D[i];
  end
  */

  // assign columns, range from 0-4
  assign C[0] = A_in[0] ^ A_in[5] ^ A_in[10] ^ A_in[15] ^ A_in[20];
  assign C[1] = A_in[1] ^ A_in[6] ^ A_in[11] ^ A_in[16] ^ A_in[21];
  assign C[2] = A_in[2] ^ A_in[7] ^ A_in[12] ^ A_in[17] ^ A_in[22];
  assign C[3] = A_in[3] ^ A_in[8] ^ A_in[13] ^ A_in[18] ^ A_in[23];
  assign C[4] = A_in[4] ^ A_in[9] ^ A_in[14] ^ A_in[19] ^ A_in[24];

  // from the formula "D[x,z] = C[(x-1)mod5,z] XOR C[(x+1)mod5,(z-1)mod w]"
  // Column in focus shifts left by 1, so just C[x-1]
  // Column in focus shifts right and get the bits in bit position - 1, so need to rotate right to get the column of bit position - 1
  function [63:0] rol1;
    input [63:0] v;
    begin
      rol1 = {v[62:0], v[63]};  // rotates left by 1 and 64th bit goes to LSB
    end
  endfunction

  // get the prities of the 64 bits data in these 2 columns 
  assign D[0] = C[4] ^ rol1(C[1]);
  assign D[1] = C[0] ^ rol1(C[2]);
  assign D[2] = C[1] ^ rol1(C[3]);
  assign D[3] = C[2] ^ rol1(C[4]);
  assign D[4] = C[3] ^ rol1(C[0]);

  // generating output
  wire [63:0] A_out[0:24];  //lens
  genvar x, y;
  generate
    for (x = 0; x < 5; x = x + 1) begin : rows
      for (y = 0; y < 5; y = y + 1) begin : columns
        assign A_out[x+(5*y)] = A_in[x+(5*y)] ^ D[x];
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

  // generating output
  genvar x, y;
  generate
    for (x = 0; x < 5; x = x + 1) begin : rows
      for (y = 0; y < 5; y = y + 1) begin : columns
        assign A_out[x+(5*y)] = A_in[(((x+(3*y)) % 5)+(5*x))];
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

// XOR each bit with a non-linear function of two other bits in its row
module chi (
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
        assign A_out[lane_no] = and_xor(A_in[lane_no], A_in[lane1_no], A_in[lane2_no]);
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

