`timescale 1ns/1ps
`define DELAY 10
module pi_tb;
  reg [1599:0] state_in;
  wire [1599:0] state_out;

  pi pi_uut(.state_in(state_in), .state_out(state_out));

  initial begin
    state_in = 1600'h0;
    $monitor("state_out:%h",state_out);
    #(`DELAY*50);
    $finish;
  end
endmodule
