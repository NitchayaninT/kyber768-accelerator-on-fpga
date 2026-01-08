module ntt_tb;
  reg [15:0] in[0:255];
  wire [15:0] out[0:255];
  reg clk;
  reg enable;
  wire valid;

  ntt uut (
      .clk(clk),
      .enable(enable),
      .in(in),
      .out(out),
      .valid(valid)
  );

  initial begin
    enable = 0;
    clk = 0;
    forever #1 clk = ~clk;
  end

  initial begin
    $readmemb("test_vect.bin", in);
    #10 enable = 1;
    wait(valid);
  end
endmodule
