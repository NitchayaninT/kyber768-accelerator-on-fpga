// Single-Port Block RAM No-Change Mode
// File: rams_sp_nc.v

module rams_sp_nc (
    clk,
    we,
    en,
    addr,
    di,
    dout
);

  input clk;
  input we;
  input en;
  input [6:0] addr;
  input [15:0] di;
  output [15:0] dout;

  reg [15:0] RAM  [128];
  reg [15:0] dout;

  initial begin
    $readmemh("rams_zetas.mem",RAM);
  end

  always @(posedge clk) begin
    if (en) begin
      if (we) RAM[addr] <= di;
      else dout <= RAM[addr];
    end
  end
endmodule
