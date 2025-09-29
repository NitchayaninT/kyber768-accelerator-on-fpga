`timescale 1ns / 1ps
`include "params.vh"

module multiplexer5x1_small_tb;
  reg [2:0] selector;
  reg [(`KYBER_N * `KYBER_SPOLY_WIDTH) - 1 : 0] in[0:3];
  reg [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] in4;  // normal size polynomials
  reg [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] out;

  multiplexer5x1_small uut (
      .selector(selector),
      .in0(in[0]),
      .in1(in[1]),
      .in2(in[2]),
      .in3(in[3]),
      .in4(in4),
      .out(out)
  );
  reg [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] buffer[0:4];  // normal size polynomials
  initial begin

    $readmemb("small_poly.bin",in);
    $readmemh("rand_poly.hex",buffer);
    in4 = buffer[0];

    #(`DELAY) selector = 3'b000;
    #(`DELAY) selector = 3'b001;
    #(`DELAY) selector = 3'b010;
    #(`DELAY) selector = 3'b011;
    #(`DELAY) selector = 3'b100;
    #(`DELAY) selector = 3'b101;
    #(`DELAY) $finish;
  end

  initial begin
        $monitor("%t: sel = %b, output %h",$time,selector,out);
  end
endmodule
