`include "params.vh"

module polyvec_basemul_montgomery_tb;
  reg  clk;
  reg  start;
  wire valid;
  reg  rst;

  polyvec_basemul_montgomery pvbm_uut (
      .clk  (clk),
      .rst  (rst),
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
    start <= 0;
    rst   <= 1;
    fd = $fopen("/home/pakin/kyber/data/test_result/polyvec_basemul.hex", "w");
    if (fd == 0) $fatal("Cant open files");
    $readmemh("pvbm_a0.mem", pvbm_uut.g_ram_in[0].ram_in0.RAM);
    $readmemh("pvbm_b0.mem", pvbm_uut.g_ram_in[0].ram_in1.RAM);
    $readmemh("pvbm_a1.mem", pvbm_uut.g_ram_in[1].ram_in0.RAM);
    $readmemh("pvbm_b1.mem", pvbm_uut.g_ram_in[1].ram_in1.RAM);
    $readmemh("pvbm_a2.mem", pvbm_uut.g_ram_in[2].ram_in0.RAM);
    $readmemh("pvbm_b2.mem", pvbm_uut.g_ram_in[2].ram_in1.RAM);
    clk <= 1;
    #2 rst <= 0;
    #10;
    start <= 1;
    #2;
    start <= 0;
    wait (valid);
    #50;
    for (i = 0; i < 128; i++) begin
      $display("index%d : %0d", (i * 2), pvbm_uut.ram_output.RAM[i][15:0]);
      $fdisplay(fd, "%h", pvbm_uut.ram_output.RAM[i][15:0]);
      $display("index%d : %0d", (i * 2 + 1), pvbm_uut.ram_output.RAM[i][31:16]);
      $fdisplay(fd, "%h", pvbm_uut.ram_output.RAM[i][31:16]);
    end
    $fclose(fd);
    $finish;
  end
endmodule
