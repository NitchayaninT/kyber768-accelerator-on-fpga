module test_tb;
  logic clk, reset, enable;
  logic [5:0] a[16];
  logic [5:0] r_wire, r_reg;

  test uut (
      .clk(clk),
      .reset(reset),
      .enable(enable),
      .a(a),
      .r_wire(r_wire),
      .r_reg(r_reg)
  );

  always #1 clk <= ~clk;

  logic [5:0] i;
  logic [3:0] index;
  assign index = uut.index;
  initial begin
    clk <= 0;
    reset <= 0;
    enable <= 0;
    index <= 0;
    for (i = 0; i < 16; i++) begin
      a[i] <= i;
    end
    #2 reset <= 1;
    #2 reset <= 0;
    enable <= 1;
    $monitor("index = %d, output r_wire = %d, output r_reg = %d ", index, r_wire, r_reg);
  end

endmodule
