module tb_fqmul;

  reg clk;
  reg signed [15:0] a, b;
  wire signed [15:0] r;

  fqmul dut (
    .clk(clk),
    .a(a),
    .b(b),
    .r(r)
  );

  // clock: 100 MHz
  always #5 clk = ~clk;

  initial begin
    clk = 0;
    a = 0;
    b = 0;

    // wait reset-free cycles
    #20;

    // test vector 1
    a = 16'sd17;
    b = 16'sd23;
    #10; // 1 cycle
    $display("r = %d", r);

    // test vector 2
    a = -16'sd1044;
    b = 16'sd287;
    #10;
    $display("r = %d", r);

    // back-to-back test
    a = 16'sd622;
    b = -16'sd171;
    #10;
    $display("r = %d", r);

    #20;
    $finish;
  end
endmodule
