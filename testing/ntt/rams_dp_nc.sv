// Single-Port Block RAM No-Change Mode
// File: rams_sp_nc.v
`include "params.vh"

module rams_dp_nc (
    input clk,
    input wea,
    input web,
    input rea,
    input reb,
    input [6:0] addra, // also adjust the addr size here
    input [6:0] addrb, // also adjust the addr size here
    input signed [`KYBER_POLY_WIDTH - 1 : 0] dia,
    input signed [`KYBER_POLY_WIDTH - 1 : 0] dib,
    output reg signed [2*`KYBER_POLY_WIDTH - 1: 0] douta,
    output reg signed [2* `KYBER_POLY_WIDTH - 1 : 0] doutb
);
  //reg signed [15:0] RAM[256];
  // try making rams 32 bits addr
  reg signed [2*`KYBER_POLY_WIDTH - 1:0] RAM[128];
  //just for testing
  /*
  initial begin
    $readmemh("rams_test_vector.mem", RAM);
  end
  */
  always @(posedge clk) begin
    if (rea) begin
      if (wea) RAM[addra] <= dia;
      else douta <= RAM[addra];
    end
  end

  always @(posedge clk) begin
    if (reb) begin
      if (web) RAM[addrb] <= dib;
      else doutb <= RAM[addrb];
    end
  end
endmodule
