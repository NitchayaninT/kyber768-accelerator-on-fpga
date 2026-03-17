`include "params.vh"

module poly_basemul_montgomery_tb;
  reg  clk;
  reg  start;
  wire valid;

  poly_basemul_montgomery pbm_uut (
      .clk  (clk),
      .start(start),
      .valid(valid)
  );

  initial begin
    forever begin
      #1 clk <= ~clk;
    end
  end

  integer i = 0;
  integer fd;
  initial begin
    fd = $fopen("/home/pakin/kyber/data/test_result/poly_basemul.hex", "w");
    if (fd == 0) $fatal("Cant open files");

    $readmemh("test_pbm_a.mem", pbm_uut.ram_in0.RAM);
    $readmemh("test_pbm_b.mem", pbm_uut.ram_in1.RAM);
    clk <= 1;
    #10;
    start <= 1;
    #2;
    start <= 0;
    wait (valid);
    #50;
    for (i = 0; i < 128; i++) begin
      $display("index%d : %0d", (i * 2), pbm_uut.ram_output.RAM[i][15:0]);
      $fdisplay(fd, "%h", pbm_uut.ram_output.RAM[i][15:0]);
      $display("index%d : %0d", (i * 2 + 1), pbm_uut.ram_output.RAM[i][31:16]);
      $fdisplay(fd, "%h", pbm_uut.ram_output.RAM[i][31:16]);
    end
    $fclose(fd);
    $finish;
  end
endmodule
