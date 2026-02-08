`include "params.vh"
module polyvec_pointwise_acc_montgomery (
    input  clk,
    input  start,
    output valid
);


  // **************************************************
  // Implement ROM with BRAM for storing zetas
  // **************************************************

  wire signed [`KYBER_POLY_WIDTH - 1:0] zeta_a;
  wire signed [`KYBER_POLY_WIDTH - 1:0] zeta_b;
  reg [6:0] rom_zeta_addr;
  rom_zetas rom_zetas (
      .clk (clk),
      .addr(rom_zeta_addr),
      .dout(zeta_a)
  );
  assign zeta_b = -zeta_a;
endmodule
