`timescale 1ns/1ps
module shake128_tb;
  reg          clk;
  reg          enable;
  reg          rst;
  reg [ 255:0] in;  // coins or seeds
  reg [   3:0] domain;  // domain separator 1111
  reg [  13:0] output_len;  // output length 
  reg [5375:0] output_string;  // max 4*R bits
  reg          done;  // done flag

  shake128 shake128_uut (
      .clk          (clk),
      .enable       (enable),
      .rst          (rst),
      .in           (in),             // coins or seeds
      .domain       (domain),         // domain separator 1111
      .output_len   (output_len),     // output length
      .output_string(output_string),  // max 4*R bits
      .done         (done)            // done flag
  );

  wire [255:0] msg_bits;
  assign msg_bits = shake128_uut.msg_bits;

  int i;
  initial begin
    rst <= 1;
    /*
    for(i=0; i<256/8; i++) begin
      in[i * 8 +: 8] <= 8'h0F;
    end*/
    in <= 256'hf8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598;

    #10 rst <= 0;
    $display("%h", in);
    wait (done);
    $display("msg_bits :%h\noutput string:%h", msg_bits, output_string);

  end

endmodule
