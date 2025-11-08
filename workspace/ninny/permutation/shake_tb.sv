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
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, shake_tb);
    $monitor("time:%t\n state_out: %h\n round: %d\n valid:%b", $time, state_out, shake_uut.round,
             valid);
    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end


  initial begin
    rst = 1;
    in  = 256'hf8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598;

    #(`DELAY) rst = 0;
    #(`DELAY) enable = 1;

    #(`DELAY * 50);
    $display("\n\nvalid : %b\n state_out = %h\n", valid, state_out);
    $display("answer : bc560b74bafdfcec6bef89337da01de833c65309e7e3cb6cfff9f5a263aabe16");
    $finish;
  end
endmodule
