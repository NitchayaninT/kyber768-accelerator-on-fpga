`timescale 1ns / 1ps

module permutation_step1_tb;
    reg  clk = 0;
    reg  rst = 1;
    reg  enable = 0;
    reg  [1599:0] state_in;
    wire [1599:0] state_out;

    permutation uut (
        .clk (clk),
        .enable (enable),
        .rst (rst),
        .state_in (state_in),
        .state_out(state_out)
    );
    initial begin
        $monitor("%t : %h",$time,state_in);
        #10 state_in = 1600'h0;
        $finish;
    end
  end
endmodule