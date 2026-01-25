`timescale 1ns / 1ps
`define DELAY 2
module rams_sp_nc_tb;
  reg clk;
  reg we;
  reg en;
  reg [6:0] addr;
  reg [15:0] di;
  wire [15:0] dout;

  rams_sp_nc uut (
      .clk (clk),
      .we  (we),
      .en  (en),
      .addr(addr),
      .di  (di),
      .dout(dout)
  );


  int i;
  initial begin
    // initial variable
    clk <= 0;
    we <= 0;
    en <= 1;
    di <= 16'h0;
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
