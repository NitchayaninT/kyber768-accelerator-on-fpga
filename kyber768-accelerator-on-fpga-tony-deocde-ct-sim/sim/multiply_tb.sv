`timescale 1ns/1ps

module multiply_tb;
  parameter int WIDTH = 8;

 // testbench signals
  reg[WIDTH-1:0] in1;
  reg[WIDTH-1:0] in2;
  reg[(2*WIDTH)-1:0] out;

  multiply #(.WIDTH(WIDTH)) uut (
    .in1(in1),
    .in2(in2),
    .out(out)
  );

  initial begin
    in1 = 0;
    in2 = 0;

    //test vector
    #10 in1 = 8'h01; in2 = 8'h01; //1*1
    #10 in1 = 8'h02; in2 = 8'h03; //2*3
    #10 in1 = 8'hF4; in2 = 8'h3D; //random
    #10 in1 = 8'h57; in2 = 8'h04; //random
    #10 $finish;
  end
  initial begin
      $display("Time\tin1\tin2\tout");
      $monitor("%0t\t%h\t%h\t%h", $time, in1, in2, out);
      $dumpfile("dump.vcd");  // VCD file name
      $dumpvars(0, tb_multiplication);      // Dump all signals in the testbench
  end
endmodule
