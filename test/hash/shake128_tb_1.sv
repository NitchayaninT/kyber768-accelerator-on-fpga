// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps
`define DELAY 5
module shake128_tb;
  reg clk;
  reg enable;
  reg rst;
  reg [255:0] in; // coins or seeds
  reg [13:0] output_len;
  reg [7:0] index_j;
  reg [7:0] index_i;
  wire [5375:0] output_string; 
  wire done;

  shake128 shake128_uut (
      .clk(clk),
      .enable(enable),
      .rst(rst),
      .in(in),
      .index_i(index_i),
      .index_j(index_j),
      .output_len(output_len),
      .output_string(output_string),
      .done(done)
  );

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, shake128_tb);
    $monitor("phase:%d\n perm_valid:%h\n perm_enable:%h\n stage_reg:%h\n bit squeezed:%d\n output len:%d\n output string:%h\n done:%d\n ", shake128_uut.phase, shake128_uut.perm_valid, shake128_uut.perm_enable, shake128_uut.state_reg, shake128_uut.bits_squeezed, shake128_uut.output_len, shake128_uut.output_string, shake128_uut.done);
    //$display("time  phase  en  round  valid  bits_squeezed");
    //$monitor("%4t  %0d    %b   %2d    %b     %0d",
           ///$time, sponge_const_uut.phase, sponge_const_uut.perm_enable, sponge_const_uut.u_perm.round, sponge_const_uut.perm_valid, sponge_const_uut.bits_squeezed);
    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end

  initial begin
    // -- INPUT -- //
    rst = 1;
    in  = 256'hf8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598;
    index_j = 0;
    index_i = 0;
    output_len = 14'd5376; // for seed (Public matrix)
    enable = 0;

    // Release reset to start loading state_reg, done, etc
    #(`DELAY) rst = 0;
    #(`DELAY) enable = 1;
    
    @(posedge done);
    #(`DELAY * 5);
    
    wait(done);
    $display("\n\ndone : %b\n output string = %h\n", done, output_string);
    $finish;
  end
endmodule