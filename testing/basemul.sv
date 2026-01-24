`include "params.vh"
module basemul (
    input  [2*`KYBER_POLY_WIDTH - 1:0] a,
    input  [2*`KYBER_POLY_WIDTH - 1:0] b,
    input  [  `KYBER_POLY_WIDTH - 1:0] zeta,
    output [ 2*`KYBER_POLY_WIDTH -1:0] r
);
  fqmul fqmul_uut()
endmodule
