`timescale 1ns/1ps
`define DELAY 10
module rho_tb;
  reg [1599:0] in;
  wire  [63:0] state_in[0:24];
  wire [63:0] state_out[0:24];

  genvar i;
  generate
    for (i = 0; i < 25; i = i + 1) begin : unpacking
      assign state_in[i] = in[i*64+:64];  //assign 64 bits to each lane
    end
  endgenerate

  rho rho_uut(.state_in(state_in), .state_out(state_out));

  initial begin
    in = {1408'h0, 192'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA};
    $monitor("state_out[0]:%h\nstate_out[1]=%h\nstate_out[3]=%h",state_out[0],state_out[1],state_out[2]);
    #(`DELAY*50);
    $finish;
  end
endmodule
