// Single-Port Block RAM No-Change Mode
// File: rams_sp_nc.v
import params_pkg::*;

module rams_dp (
    input clk,
    input wea,
    input web,
    input ena,
    input enb,
    input [6:0] addra,  // also adjust the addr size here
    input [6:0] addrb,  // also adjust the addr size here
    input [2*KYBER_POLY_WIDTH - 1 : 0] dina,
    input [2*KYBER_POLY_WIDTH - 1 : 0] dinb,
    output reg [2*KYBER_POLY_WIDTH - 1:0] douta,
    output reg [2* KYBER_POLY_WIDTH - 1 : 0] doutb
);

  //reg signed [15:0] RAM[256];
  // try making rams 32 bits addr
  reg [2*KYBER_POLY_WIDTH - 1:0] RAM[128];
  always @(posedge clk) begin
    if (ena) begin
      if (wea) RAM[addra] <= dina;
      else douta <= RAM[addra];
    end
  end

  always @(posedge clk) begin
    if (enb) begin
      if (web) RAM[addrb] <= dinb;
      else doutb <= RAM[addrb];
    end
  end
endmodule
