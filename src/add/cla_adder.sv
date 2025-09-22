`timescale 1ns / 1ps
`define DELAY 10
// fpga4student.com FPGA projects, Verilog projects, VHDL projects
// Verilog code for carry look-ahead adder

// this are slightly modified to match use case of kyber
module cla_adder #(
    parameter int DATA_WID = 12
) (
    in1,
    in2,
    //carry_in,
    sum
    //carry_out
);

  input [DATA_WID - 1:0] in1;
  input [DATA_WID - 1:0] in2;
  //input carry_in;
  output [DATA_WID :0] sum; // modified this bit width from DATA_WID-1 to DATA_WIDTH
  //output carry_out;

  //assign {carry_out, sum} = in1 + in2 + carry_in;

  wire [DATA_WID - 1:0] gen;
  wire [DATA_WID - 1:0] pro;
  wire [DATA_WID:0] carry_tmp;

  genvar j, i;
  generate
    //assume carry_tmp in is zero
    assign carry_tmp[0] = 0;//carry_in;

    //carry generator
    for (j = 0; j < DATA_WID; j = j + 1) begin : g_carry
      assign gen[j] = in1[j] & in2[j];
      assign pro[j] = in1[j] | in2[j];
      assign carry_tmp[j+1] = gen[j] | pro[j] & carry_tmp[j];
    end

    //calculate sum
    //assign sum[0] = in1[0] ^ in2 ^ carry_in;
    for (i = 0; i < DATA_WID; i = i + 1) begin : g_sum_without_carry
      assign sum[i] = in1[i] ^ in2[i] ^ carry_tmp[i];
    end

    // In our implementation we don't need carry out but we expand the bit
    // instead
    //carry out
    //assign carry_out = carry_tmp[DATA_WID];
    assign sum[DATA_WID] = carry_tmp[DATA_WID];
  endgenerate
endmodule
