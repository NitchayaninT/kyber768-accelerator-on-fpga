`timescale 1ns / 1ps

module theta_tb;
    reg  clk = 0;
    reg  rst = 1;
    reg  enable = 0;
    reg  [1599:0] state_in;
    wire [1599:0] state_out;
    wire [63:0] d_test [0:4];

    theta uut (
        .clk (clk),
        .enable (enable),
        .d_test(d_test),
        .rst (rst),
        .state_in (state_in),
        .state_out(state_out)
    );

    initial begin
        $monitor("time:%t\n in:%h\n out=%h\n d0=%b\n d1=%b\n d2=%b\n d3=%b\n d4=%b",$time,state_in,state_out, d_test[0], d_test[1],d_test[2],d_test[3],d_test[4]);
        #10 state_in = 1600'h0;
        #10 state_in = 1600'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000AAAAAAAAAAAAAAAA5555555555555555AAAAAAAAAAAAAAAA5555555555555555AAAAAAAAAAAAAAAA;
        $finish;
    end
endmodule
