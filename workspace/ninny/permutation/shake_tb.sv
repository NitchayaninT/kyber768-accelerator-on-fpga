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
      ._in(in),
      .state_out(state_out),
      .valid(valid)
  );
  initial begin
    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end


  initial begin
    rst = 1;

    #(`DELAY) rst = 0;
    enable = 1;
    $display(" valid : %b\n state_out = %h\n");
    in = f8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598;

    #(`DELAY * 20) $display(" valid : %b\n state_out = %h\n");
    $display("verify : bc560b74bafdfcec6bef89337da01de833c65309e7e3cb6cfff9f5a263aabe16\n");
    in = b6277f58b599c2008f588b3a47968eb38d927675142bea9bc2563b331534d648;

    #(`DELAY * 20) $display(" valid : %b\n state_out = %h\n");
    $display("verify : 75b7cbc048a28897fe1a34003c87af24c7f5a4c92f2cd60bbbb0b275404b2df8\n");
    in = fab44467355896793590719575756939aca84406c61db80411edc717f195b8cb;

    #(`DELAY * 20) $display(" valid : %b\n state_out = %h\n");
    $display("verify : 8e6664e8658ee7c858d898c4678fc52f41d3baa73f2c7957085cf105ff1226e5\n");
    in = bb426db51db8f17de0578e6f7c946d5e4778381f98e8be86d3f98ae06bf963b7;

    #(`DELAY * 20) $display(" valid : %b\n state_out = %h\n");
    $display("verify : a3b629f4e92b76e3579a0e076e863920c1efb5b1184fe4a1f9f9467202b2e88c\n");
    $finish;
  end
endmodule
