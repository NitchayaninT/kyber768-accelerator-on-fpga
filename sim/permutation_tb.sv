// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps
`define DELAY 10
module permutation_tb;

  reg clk;
  reg enable;
  reg rst;
  reg [1599:0] in;
  wire [1599:0] state_out;
  wire valid;

  permutation permutation_uut (
      .clk(clk),
      .enable(enable),
      .rst(rst),
      .in(in),
      .state_out(state_out),
      .valid(valid)
  );

  task print_lane_bytes_be(input [63:0] lane, input integer idx);
    $display("%2d: %02h%02h%02h%02h%02h%02h%02h%02h", idx, lane[63:56], lane[55:48], lane[47:40],
             lane[39:32], lane[31:24], lane[23:16], lane[15:8], lane[7:0]);
  endtask

  task print_state_bytes(input [1599:0] S);
    integer i;
    reg [63:0] lane;
    begin
      for (i = 0; i < 25; i = i + 1) begin
        lane = S[i*64+:64];  // i = x + 5*y 
        print_lane_bytes_be(lane, i);
      end
    end
  endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, permutation_tb);
   // $monitor("time:%t\n state_out: %h\n round: %d\n valid:%b", $time, state_out, shake_uut.round,valid);
    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end

  initial begin
    rst = 1;
    in  = 1600'hda53783742352b58831b00174ccd88e7779a0405cf14e8b61df27a112b2459962267de9879022d8335df49b23ab1bf9cff3b716e2b7ce4cb65ae7a2a6191756f65b55880eddb41052c9b91ea13d70e98150014c7fd2ad9358df4416e4894e9b1d4254ec87d07377333e9cff0afb9aed51c5f90109184a7f46ed9d0a2e48063a20ce98471b8289bf9affef18e0b8909149e33bf132b2a456d8c0a0f6a837059d9543690e584e6ebde0ff523a3b9ad4b80aebe348c6bf79ec031db51b4dc6a2ba53218786e98d39b40;

    #(`DELAY) rst = 0;
    #(`DELAY) enable = 1;
    #(`DELAY * 50);
    $display("\n\nvalid : %b\n state_out = %h\n", valid, state_out);
    $display("answer : bc560b74bafdfcec6bef89337da01de833c65309e7e3cb6cfff9f5a263aabe16");
    $finish;
  end
endmodule