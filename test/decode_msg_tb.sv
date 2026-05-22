`timescale 1ns / 1ps
`include "params.vh"

module decode_msg_tb;

  // test signal
  reg [`KYBER_N - 1:0] msg;
  reg [(`KYBER_N * `KYBER_R_WIDTH)-1:0] poly_msg;

  decode_msg uut (
      .msg(msg),
      .poly_msg(poly_msg)
  );

  initial begin
    msg = 0;

    //test vector
    #5 msg = 256'h5c5d501a5670243b8fc6d100cf96e25f174ba1e6a5bf2407a51b51727175978a;
    #5 msg = 256'he9daa4f77c132dcae97933bb75895e20cab2d036a2b31817515091dec2e09682;
    #5 msg = 256'hf145fa82c7872e2bae12f7bf45ae196b779d2fd83aaa8a6485fbad0fb0c30fe3;
    #5 msg = 256'h3d8b2696015507949051213a6f7380a2e8c2a805d0ef5d4d4ecf4dcb1fd7a833;
    #10 $finish;
  end

  initial begin
    $monitor("%0t\t%h\t%h", $time, msg, poly_msg);
    $dumpfile("dump.vcd");  // VCD file name
    $dumpvars(0, decode_msg_tb);  // Dump all signals in the testbench
  end
endmodule
