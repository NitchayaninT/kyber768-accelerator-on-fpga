`timescale 1ns / 1ps
`include "params.vh"

module add_tb;
  reg signed [`KYBER_POLY_WIDTH - 1:0] a[`KYBER_N];
  reg signed [`KYBER_POLY_WIDTH - 1:0] b[`KYBER_N];
  reg signed [`KYBER_POLY_WIDTH - 1:0] r[`KYBER_N];

  add add_uut (
      .a(a),
      .b(b),
      .r(r)
  );

  int i;
  int fd;
  initial begin
    fd = $fopen("/home/pakin/kyber/data/test_result/add.hex", "w");
    $readmemh("/home/pakin/kyber/data/test_case/add_a.mem", a);
    $readmemh("/home/pakin/kyber/data/test_case/add_b.mem", b);
    #10
    for (i = 0; i < 256; i++) begin
      $fdisplay(fd, "h", r[i],);
    end
    $fclose(fd);
    $finish;
  end
endmodule
