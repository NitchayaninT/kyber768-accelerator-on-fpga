// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps
`define DELAY 3
module sha3_512_tb;

  reg clk;
  reg enable;
  reg rst;
  reg [511:0] in; // PK or random bits
  reg [13:0] input_len;
  wire [511:0] output_string; 
  wire done;

  sha3_512 sha3_512_uut (
      .clk(clk),
      .enable(enable),
      .rst(rst),
      .in(in),
      .input_len(input_len),
      .output_string(output_string),
      .done(done)
  );

 task print_state_bytes(input [511:0] S);
    integer b;
    localparam integer NUM_BYTES = 512 / 8;  // 64
    reg [511:0] python_order;
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
    $dumpvars(0, sha3_512_tb);
    $monitor("phase:%d\n perm_valid:%h\n perm_enable:%h\n total_bytes_index:%d\n block no:%d\n msg_len_bytes:%d\n stage_reg:%h\n input len:%d\n output string:%h\n ", sha3_512_uut.phase, sha3_512_uut.perm_valid, sha3_512_uut.perm_enable, sha3_512_uut.total_bytes_index, sha3_512_uut.absorb_idx, sha3_512_uut.msg_len_bytes, sha3_512_uut.state_reg, sha3_512_uut.input_len, sha3_512_uut.output_string);

    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end

  initial begin
    // -- INPUT -- //
    rst = 1;
    // input len = 512 bits
    in = 512'hccfe46740b8c497c45165b4c584570c7d8801b74ec88127cbe5ab1ce686f9b5624a0701c421866cadb1c950d6c3e076ee0d1d1e2b8538a5105e2f2434d385723;
    input_len = 10'd512; // for PK
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