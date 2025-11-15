module ntt_tb;
  reg [15:0] in [256];
  wire [15:0] out [256];
  reg clk;
  reg enable;
  wire valid;
  
  ntt uut(
    .clk(clk),
    .enable(enable),
    .in(in),
    .out(out),
    .valid(valid)
  );


  initial begin
    $readmemb("test_vect.bin",in);
    #10 enable = 1;
    #50 $display("out", out);
  end
endmodule
