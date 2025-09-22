`timescale 1ns/1ps
`include "params.vh"

module expand_small_tb;
  reg [`KYBER_SPOLY_WIDTH - 1 : 0] in;
  reg [`KYBER_R_WIDTH - 1 : 0] out;

  expand_small uut(.in(in), .out(out));

  initial begin
    $monitor("time:%t  small_poly:%b poly:%d", $time, in, out);
    $dumpfile("dump.vcd");
    $dumpvars(0,expand_small_tb);

    #10 in = 3'b000;
    #10 in = 3'b001;
    #10 in = 3'b010;
    #10 in = 3'b111;
    #10 in = 3'b110;
    #10 in = 3'b100;
    #10 in = 3'b011;
  end
endmodule
