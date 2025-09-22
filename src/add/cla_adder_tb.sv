`timescale 1ns / 1ps
`define DELAY 10

module cla_adder_tb ();
  parameter int DATA_WID = 12;
  // fpga4student.com FPGA projects, Verilog projects, VHDL projects
  // Verilog testbench code for carry look ahead adder
  reg carry_in;  // To cla1 of cla_adder.v
  reg [DATA_WID-1:0] in1;  // To cla1 of cla_adder.v
  reg [DATA_WID-1:0] in2;  // To cla1 of cla_adder.v

  //wire carry_out;  // From cla1 of cla_adder.v
  wire [DATA_WID:0] sum;  // From cla1 of cla_adder.v

  cla_adder cla1 (  /*AUTOINST*/
      //  Outputs
      .sum(sum[DATA_WID:0]),
      //.carry_out(carry_out),
      // // Inputs
      .in1(in1[DATA_WID-1:0]),
      .in2(in2[DATA_WID-1:0]),
      .carry_in(carry_in)
  );

  initial begin
    in1 = 12'd0;
    in2 = 12'd0;
    carry_in = 1'b0;
  end
  initial begin
    #(`DELAY) #(`DELAY) in1 = 12'd10;
    #(`DELAY) in1 = 12'd20;
    #(`DELAY) in2 = 12'd10;
    #(`DELAY) in2 = 12'd20;
    #(`DELAY) in2 = 12'd0;
    #(`DELAY) in1 = 12'd256;
    #(`DELAY) in1 = 12'd3329;
    in2 = 12'd3329;
    #(`DELAY) in1 = 12'd3329;
    in2 = 12'd3329;
    #(`DELAY * 3) $finish;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, cla_adder_tb);
  end

endmodule
