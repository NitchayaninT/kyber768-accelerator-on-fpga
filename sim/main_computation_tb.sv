`timescale 1ns / 1ps
import params_pkg::*;
import enums_pkg::*;

`define HIGHER_BITS 31:16
`define LOWER_BITS 15:0

module main_computation_tb;
  main_compute_mode_e mode;

  logic clk, reset, enable;
  logic [KYBER_POLY_WIDTH-1 : 0] a_t[0:(KYBER_K*KYBER_K)-1][0:KYBER_N-1];
  logic [KYBER_POLY_WIDTH-1:0] r[0:KYBER_K-1][0:KYBER_N-1];
  logic [(KYBER_N * KYBER_RQ_WIDTH)-1:0] t_vec[3];

  logic signed [KYBER_POLY_WIDTH-1:0] u[0:KYBER_K-1][0:KYBER_N-1];
  logic signed [KYBER_POLY_WIDTH-1:0] v[0:KYBER_N-1];

  logic [KYBER_POLY_WIDTH - 1:0] t_vec_transform[KYBER_K][KYBER_N];
  genvar i, j;
  generate
    for (j = 0; j < 3; j++) begin : g_t_vec_trans_k
      for (i = 0; i < 256; i++) begin : g_t_vec_trans_n
        assign t_vec[j][KYBER_RQ_WIDTH*i+:KYBER_RQ_WIDTH] = 12'(t_vec_transform[j][i]);
      end
    end
  endgenerate
  logic valid;

  main_computation main_computation (
      .clk   (clk),
      .enable(enable),
      .reset (reset),
      .mode  (mode),
      .a_t   (a_t),
      .r     (r),
      .u     (u),
      .v     (v),
      .t_vec (t_vec),
      .valid (valid)
  );

  function automatic logic compare_helper(input logic [KYBER_POLY_WIDTH-1:0] net_in[256],
                                          input logic [2* KYBER_POLY_WIDTH-1:0] ram[128]);
    int   i;
    logic equal = 1;

    for (i = 0; i < 128; i++) begin
      if (net_in[2*i] != ram[i][`LOWER_BITS]) equal = 0;
      if (net_in[2*i+1] != ram[i][`HIGHER_BITS]) equal = 0;
    end
    return equal;
  endfunction

  task automatic compare_load_ram(input logic [KYBER_POLY_WIDTH-1:0] net_in[256],
                                  input logic [2* KYBER_POLY_WIDTH-1:0] ram[128],
                                      input string name);
    logic equal = compare_helper(net_in, ram);
    if (equal) $display("LOAD_RAM %s : CORRECT", name);
    else $display("LOAD_RAM %s : INCORRECT", name);
  endtask

  always #1 clk <= ~clk;

  int fd;
  int index;
  initial begin
    clk <= 0;
    enable <= 0;
    reset <= 0;
    mode <= ENC;

    $readmemh("at0.mem", a_t[0]);
    $readmemh("at1.mem", a_t[1]);
    $readmemh("at2.mem", a_t[2]);
    $readmemh("at3.mem", a_t[3]);
    $readmemh("at4.mem", a_t[4]);
    $readmemh("at5.mem", a_t[5]);
    $readmemh("at6.mem", a_t[6]);
    $readmemh("at7.mem", a_t[7]);
    $readmemh("at8.mem", a_t[8]);

    $readmemh("tvec0.mem", t_vec_transform[0]);
    $readmemh("tvec1.mem", t_vec_transform[1]);
    $readmemh("tvec2.mem", t_vec_transform[2]);

    $readmemh("r0.mem", r[0]);
    $readmemh("r1.mem", r[1]);
    $readmemh("r2.mem", r[2]);

    #2 reset <= 1;
    #2 reset <= 0;
    #6 enable <= 1;
    #2 enable <= 0;

    wait (main_computation.lr_done);
    $display("Checkpoint 1 : LOAD_RAM");
    compare_load_ram(a_t[0], main_computation.g_bram[0].rams_dp.RAM, "a_t0");
    compare_load_ram(a_t[1], main_computation.g_bram[1].rams_dp.RAM, "a_t1");
    compare_load_ram(a_t[2], main_computation.g_bram[2].rams_dp.RAM, "a_t2");
    compare_load_ram(a_t[3], main_computation.g_bram[3].rams_dp.RAM, "a_t3");
    compare_load_ram(a_t[4], main_computation.g_bram[4].rams_dp.RAM, "a_t4");
    compare_load_ram(a_t[5], main_computation.g_bram[5].rams_dp.RAM, "a_t5");
    compare_load_ram(a_t[6], main_computation.g_bram[6].rams_dp.RAM, "a_t6");
    compare_load_ram(a_t[7], main_computation.g_bram[7].rams_dp.RAM, "a_t7");
    compare_load_ram(a_t[8], main_computation.g_bram[8].rams_dp.RAM, "a_t8");
    compare_load_ram(t_vec_transform[0], main_computation.g_bram[9].rams_dp.RAM, "t_vec0");
    compare_load_ram(t_vec_transform[1], main_computation.g_bram[10].rams_dp.RAM, "t_vec1");
    compare_load_ram(t_vec_transform[2], main_computation.g_bram[11].rams_dp.RAM, "t_vec2");
    compare_load_ram(r[0], main_computation.g_bram[12].rams_dp.RAM, "r0");
    compare_load_ram(r[1], main_computation.g_bram[13].rams_dp.RAM, "r1");
    compare_load_ram(r[2], main_computation.g_bram[14].rams_dp.RAM, "r2");

    #10;
    wait (main_computation.ntt_done);
    fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/ntt0.hex", "w");
    for (index = 0; index < 128; index++) begin
      $fdisplay(fd, "%h", main_computation.g_bram[12].rams_dp.RAM[index][15:0]);
      $fdisplay(fd, "%h", main_computation.g_bram[12].rams_dp.RAM[index][31:16]);
    end
    $fclose(fd);

    fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/ntt1.hex", "w");
    for (index = 0; index < 128; index++) begin
      $fdisplay(fd, "%h", main_computation.g_bram[13].rams_dp.RAM[index][15:0]);
      $fdisplay(fd, "%h", main_computation.g_bram[13].rams_dp.RAM[index][31:16]);
    end
    $fclose(fd);

    fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/ntt2.hex", "w");
    for (index = 0; index < 128; index++) begin
      $fdisplay(fd, "%h", main_computation.g_bram[14].rams_dp.RAM[index][15:0]);
      $fdisplay(fd, "%h", main_computation.g_bram[14].rams_dp.RAM[index][31:16]);
    end
    $fclose(fd);

    #10 wait (main_computation.pvbm_done);
    fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/pvbm_at0.hex", "w");
    for (index = 0; index < 128; index++) begin
      $fdisplay(fd, "%h", main_computation.g_bram[0].rams_dp.RAM[index][15:0]);
      $fdisplay(fd, "%h", main_computation.g_bram[0].rams_dp.RAM[index][31:16]);
    end
    $fclose(fd);

    fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/pvbm_at1.hex", "w");
    for (index = 0; index < 128; index++) begin
      $fdisplay(fd, "%h", main_computation.g_bram[3].rams_dp.RAM[index][15:0]);
      $fdisplay(fd, "%h", main_computation.g_bram[3].rams_dp.RAM[index][31:16]);
    end
    $fclose(fd);

    fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/pvbm_at2.hex", "w");
    for (index = 0; index < 128; index++) begin
      $fdisplay(fd, "%h", main_computation.g_bram[6].rams_dp.RAM[index][15:0]);
      $fdisplay(fd, "%h", main_computation.g_bram[6].rams_dp.RAM[index][31:16]);
    end
    $fclose(fd);

    fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/pvbm_tvec.hex", "w");
    for (index = 0; index < 128; index++) begin
      $fdisplay(fd, "%h", main_computation.g_bram[9].rams_dp.RAM[index][15:0]);
      $fdisplay(fd, "%h", main_computation.g_bram[9].rams_dp.RAM[index][31:16]);
    end
    $fclose(fd);
    #10
    wait (main_computation.inv_ntt_done) begin
      fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/inv_ntt_at0.hex", "w");
      for (index = 0; index < 128; index++) begin
        $fdisplay(fd, "%h", main_computation.g_bram[0].rams_dp.RAM[index][15:0]);
        $fdisplay(fd, "%h", main_computation.g_bram[0].rams_dp.RAM[index][31:16]);
      end
      $fclose(fd);

      fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/inv_ntt_at1.hex", "w");
      for (index = 0; index < 128; index++) begin
        $fdisplay(fd, "%h", main_computation.g_bram[3].rams_dp.RAM[index][15:0]);
        $fdisplay(fd, "%h", main_computation.g_bram[3].rams_dp.RAM[index][31:16]);
      end
      $fclose(fd);

      fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/inv_ntt_at2.hex", "w");
      for (index = 0; index < 128; index++) begin
        $fdisplay(fd, "%h", main_computation.g_bram[6].rams_dp.RAM[index][15:0]);
        $fdisplay(fd, "%h", main_computation.g_bram[6].rams_dp.RAM[index][31:16]);
      end
      $fclose(fd);

      fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/inv_ntt_tvec.hex", "w");
      for (index = 0; index < 128; index++) begin
        $fdisplay(fd, "%h", main_computation.g_bram[9].rams_dp.RAM[index][15:0]);
        $fdisplay(fd, "%h", main_computation.g_bram[9].rams_dp.RAM[index][31:16]);
      end
      $fclose(fd);
    end

    #10 fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/u0.hex", "w");
    for (index = 0; index < 256; index++) begin
      $fdisplay(fd, "%h", u[0][index]);
    end
    $fclose(fd);

    fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/u1.hex", "w");
    for (index = 0; index < 256; index++) begin
      $fdisplay(fd, "%h", u[1][index]);
    end
    $fclose(fd);

    fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/u2.hex", "w");
    for (index = 0; index < 256; index++) begin
      $fdisplay(fd, "%h", u[2][index]);
    end
    $fclose(fd);

    fd = $fopen("/home/pakin/kyber/data/test_result/main_compute/v.hex", "w");
    for (index = 0; index < 256; index++) begin
      $fdisplay(fd, "%h", v[index]);
    end
    $fclose(fd);
    $display("done");
    #20 $finish;
  end

endmodule
