`timescale 1ns / 1ps
`define DELAY 10
module shake_tb;

  reg clk;
  reg enable;
  reg rst;
  reg [255:0] in;
  wire [1599:0] state_out;
  wire valid;

  shake shake_uut (
      .clk(clk),
      .enable(enable),
      .rst(rst),
      .in(in),
      .state_out(state_out),
      .valid(valid)
  );

  always @(shake_uut.round) begin
    $display("After theta (round %d)", shake_uut.round);
    print_state_bytes(shake_uut.theta_out);
    $display("After rho   (round %d)", shake_uut.round);
    print_state_bytes(shake_uut.rho_out);
    $display("After pi    (round %d)", shake_uut.round);
    print_state_bytes(shake_uut.pi_out);
    $display("After chi   (round %d)", shake_uut.round);
    print_state_bytes(shake_uut.chi_out);
    $display("After iota  (round %d)", shake_uut.round);
    print_state_bytes(shake_uut.iota_out);
    $display("OUTPUT (after round)");
    print_state_bytes(shake_uut.state_out);
  end

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
    $dumpvars(0, shake_tb);
    //$monitor("time:%t\n state_out: %h\n round: %d\n valid:%b", $time, state_out, shake_uut.round,
    //        valid);
    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end

  initial begin
    rst = 1;
    in  = 256'hf8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598;

    #(`DELAY) rst = 0;
    #(`DELAY) enable = 1;
    #(`DELAY * 50);
    $display("\n\nvalid : %b\n state_out = ", valid);
    print_state_bytes(state_out);
    $display("answer : bc560b74bafdfcec6bef89337da01de833c65309e7e3cb6cfff9f5a263aabe16");
    $finish;
  end
endmodule