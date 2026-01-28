// Single-Port Block RAM No-Change Mode
// File: rams_sp_nc.v

module rom_zetas(
    input clk,
    input [6:0] addr,
    output reg signed [15 :0] dout
);

  reg signed [15:0] RAM [128];

  initial begin
    $readmemh("rom_zetas.mem",RAM);
  end

  always @(posedge clk) begin
    dout <= RAM [addr];
  end
endmodule
