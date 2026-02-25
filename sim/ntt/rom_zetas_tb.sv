`timescale 1ns / 1ps
`define DELAY 2
module rom_zetas_tb;
  reg clk;
  reg ena;
  reg enb;
  reg [6:0] addr;
  wire signed [15:0] dout;

  rom_zetas uut (
      .clk (clk),
      .addr(addr),
      .dout(dout)
  );


int i;
  initial begin
    // initial variable
    clk <= 0;
    ena <= 1;
    enb <= 1;
    #10
    for(i=0; i<128;i++) begin
      addr <= i;
      $display("Address %d : %d\n", addr, dout);
      #(`DELAY);
    end
  end

  initial begin
    forever begin
      #(`DELAY);
      clk <= ~clk;
    end
  end
endmodule
