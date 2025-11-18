// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps
`define DELAY 10
module sponge_const_tb;

  reg clk;
  reg enable;
  reg rst;
  reg [255:0] in; // coins or seeds
  reg [3:0] domain;
  reg [13:0] output_len;
  wire [5375:0] output_string;
  wire done;

  sponge_const sponge_const_uut (
      .clk(clk),
      .enable(enable),
      .rst(rst),
      .in(in),
      .domain(domain),
      .output_len(output_len),
      .output_string(output_string),
      .done(done)
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
    $dumpvars(0, sponge_const_tb);
    //$monitor("time:%t\n state_out: %h\n round: %d\n valid:%b", $time, state_out, shake_uut.round,
    //        valid);
    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end

  initial begin
    // -- INPUT -- //
    rst = 1;
    in  = 256'hf8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598;
    domain = 4'b1111;
    output_len = 14'd1024; // for coins 
    enable = 0;

    // Release reset to start loading state_reg, done, etc
    #(`DELAY) rst = 0;

    // Start SHAKE 
    // Absorption is wired, so its computed when our inputs are ready
    // Squeezing is in FSM
    #10 enable = 1;
    #10 enable = 0; // 1 pulse

    // wait until done
    wait(done == 1);
    #10;

    // if output_len is 1024 = trim the last 1344-1024 bits
    reg [1023:0] coins;
    if (output_len == 14'd1024) begin
      coins = output_string[1023:0];
      $display("\n\nvalid : %b\n output string = %h\n", done, coins);
    end
    else begin
      $display("\n\nvalid : %b\n output string = %h\n", done, output_string);
    end
    $finish;
  end
endmodule