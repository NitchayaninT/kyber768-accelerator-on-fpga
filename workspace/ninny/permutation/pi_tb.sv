`timescale 1ns/1ps
`define DELAY 10
module pi_tb;
  reg [1599:0] state_in;
  wire [63:0] state_out[0:24];

  genvar i;
  generate
    for (i = 0; i < 25; i = i + 1) begin : unpacking
      assign state_in[i] = in[i*64+:64];  //assign 64 bits to each lane
    end
  endgenerate

  pi pi_uut(.state_in(state_in), .state_out(state_out));

  initial begin
    in = 1600'h0;
    $monitor("state_out:%h",state_out[0]);
    #(`DELAY*50);
    $finish;
  end
endmodule
