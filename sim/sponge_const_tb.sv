// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps
`define DELAY 5
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

 task print_state_bytes(input [5375:0] S);
    integer b;
    localparam integer NUM_BYTES = 5376 / 8;  // 672
    reg [5375:0] python_order;
    begin
        // reverse bytes
        for (b = 0; b < NUM_BYTES; b = b + 1) begin
            // python order 0 print shake's last byte (right most), just map reverse order
            // this is for better displaying that left most is LSB
            // now SHAKE also prints from actual LSB to MSB like in python
            python_order[8*b +: 8] = S[8*(NUM_BYTES-1-b) +: 8];
        end
        // print as hex
        $display("python_order = %h", python_order);
    end
endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, sponge_const_tb);
    $monitor("phase:%d\n perm_valid:%h\n perm_enable:%h\n stage_reg:%h\n bit squeezed:%d\n output len:%d\n output string:%h\n ", sponge_const_uut.phase, sponge_const_uut.perm_valid, sponge_const_uut.perm_enable, sponge_const_uut.state_reg, sponge_const_uut.bits_squeezed, sponge_const_uut.output_len, sponge_const_uut.output_string);
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
    domain = 4'b1111;
    output_len = 14'd1024; // for coins 
    // output_len = 14'd5376; // for seed (Public matrix)
    enable = 0;

    // Release reset to start loading state_reg, done, etc
    #(`DELAY) rst = 0;
    #(`DELAY) enable = 1;
    
    @(posedge done);
    #(`DELAY * 5);
    
    $display("\n\ndone : %b\n output string = %h\n", done, output_string);
    print_state_bytes(output_string);
    $finish;
  end
endmodule