`timescale 1ns / 1ps
`define DELAY 2
import params_pkg::*;
module rom_zetas_tb;
  reg clk;
  reg ena;
  reg enb;
  reg [6:0] addra;
  reg [6:0] addrb;
  wire signed [15:0] douta;
  wire signed [15:0] doutb;

  rom_zetas #() rom_zetas (
      .clk  (clk),
      .addra(addra),
      .addrb(addrb),
      .douta(douta),
      .doutb(doutb)
  );

  logic [MC_ZETA_ADDR_BITS -1:0] i;
  initial begin
    // initial variable
    clk   <= 0;
    ena   <= 1;
    enb   <= 0;
    addra <= 0;
    addrb <= 0;
    //enb <= 1;
    #10
    for (i = 0; i < 128; i++) begin
      addra <= i;
      $display("Address %d : %d\n", addra, douta);
      #(`DELAY);
    end
  end

  always #`DELAY clk = ~clk;

endmodule
