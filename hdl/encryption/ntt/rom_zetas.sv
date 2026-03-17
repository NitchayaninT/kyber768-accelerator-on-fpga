// Single-Port Block RAM No-Change Mode
// File: rams_sp_nc.v
import params_pkg::*;
module rom_zetas (
    input clk,
    input [MC_ZETA_ADDR_BITS - 1:0] addra,
    input [MC_ZETA_ADDR_BITS - 1:0] addrb,
    output logic signed [KYBER_POLY_WIDTH - 1:0] douta,
    output logic signed [KYBER_POLY_WIDTH - 1:0] doutb
);

  logic signed [KYBER_POLY_WIDTH - 1:0] RAM[128];

  initial begin
    $readmemh("rom_zetas.mem", RAM);
  end

  always @(posedge clk) begin
    douta <= RAM[addra];
    doutb <= RAM[addrb];
  end
endmodule
