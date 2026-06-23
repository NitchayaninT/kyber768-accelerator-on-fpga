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
    $readmemh(
        "C:/Users/User/Desktop/Post-Quantum-Cryptography-Accelerator/hdl/encryption/main_computation/rom_zetas_inv.mem",
        RAM
    );
    // synthesis translate_off
    if ($isunknown(RAM[0]))
      $fatal(1, "Failed to load rom_zetas_inv.mem");
    // synthesis translate_on
  end

  always @(posedge clk) begin
    douta <= RAM[addra];
    doutb <= RAM[addrb];
  end
endmodule
