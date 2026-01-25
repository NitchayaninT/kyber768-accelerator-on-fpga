`include "params.vh"
`define DELAY 2

module basemul_tb;

    reg signed [`KYBER_POLY_WIDTH - 1:0] a[2];
    reg signed [`KYBER_POLY_WIDTH - 1:0] b[2];
    reg signed [`KYBER_POLY_WIDTH - 1:0] zeta;
    reg signed [`KYBER_POLY_WIDTH - 1:0] r[2];

    initial begin
      a[0] <= 0;
      a[1] <= 0;
      b[0] <= 0;
      b[1] <= 0;
      zeta <= 0;
      #10;
      a[0] <= 16'hc4b8;
      a[1] <= 16'he9f6;
      b[0] <= 16'h5592;
      b[1] <= 16'h8b66;
      zeta <= 16'h08ed;
      #10;
      a[0] <= 16'h3ef1;
      a[1] <= 16'h9047;
      b[0] <= 16'hf78d;
      b[1] <= 16'h33d8;
      zeta <= 16'h08ed;
    end

    initial begin
      $monitor("a = %h\nb = %h\nr = %h", a, b, r);
    end
endmodule
