`include "params.vh"

module poly_basemul_montgomery_tb;
  reg clk;
  reg start;
  wire signed [`KYBER_POLY_WIDTH - 1 : 0] r [`KYBER_N];

  poly_basemul_montgomery pbm_uut(
    .clk(clk),
    .start(start),
    .r(r)
  );

  initial begin
    $monitor("basemul0 : r[0] = %d [r1] =%d\nbasemul1 : r[0] = %d r[1] = %d\n\n",
    pbm_uut.basemul_r[0][0], pbm_uut.basemul_r[0][1],
    pbm_uut.basemul_r[1][0], pbm_uut.basemul_r[1][1]);
    forever begin
        #1 clk <= ~clk;
    end
   end
   
  integer i = 0;
  initial begin
      $readmemh("test_pbm_a.mem", pbm_uut.g_rams_input[0].rams_in.RAM);
      $readmemh("test_pbm_b.mem", pbm_uut.g_rams_input[1].rams_in.RAM);
    clk <= 1;
    #10;
    start <= 1;
    #2;
    start <= 0;
    #1000;
    $finish;
  end
endmodule