// Single-Port Block RAM No-Change Mode
// File: rams_sp_nc.v

module rom_zetas_inv (
    input clk,
    input [6:0] addra,
    input [6:0] addrb,
    output reg signed [15 : 0] douta,
    output reg signed [15 : 0] doutb
);

  reg signed [15:0] RAM[128];

  initial begin
    $readmemh("rom_zetas_inv.mem", RAM);
  end

  always @(posedge clk) begin
    douta <= RAM[addra];
    doutb <= RAM[addrb];
  end
endmodule
