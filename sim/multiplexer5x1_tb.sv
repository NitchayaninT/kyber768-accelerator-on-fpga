`timescale 1ns / 1ps
`include "params.vh"

module multiplexer5x1_tb ();
  reg [2:0] selector;
  reg [(`KYBER_N * 12) - 1 : 0] in[0:4];
  reg [(`KYBER_N * 12) - 1 : 0] out;

  multiplexer5x1 uut (
      .selector(selector),
      .in0(in[0]),
      .in1(in[1]),
      .in2(in[2]),
      .in3(in[3]),
      .in4(in[4]),
      .out(out)
  );

  integer i;
  initial begin
    $readmemh("rand_poly.hex", in);

    #(`DELAY) selector = 3'b000;
    #(`DELAY) selector = 3'b001;
    #(`DELAY) selector = 3'b010;
    #(`DELAY) selector = 3'b011;
    #(`DELAY) selector = 3'b100;
    #(`DELAY) selector = 3'b101;
    #(`DELAY) $finish;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, multiplexer5x1_tb);
    $monitor("%t: sel = %b, output %h",$time,selector,out);
  end
endmodule
