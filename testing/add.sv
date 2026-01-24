`include "params.vh"
module add (
    input  [`KYBER_POLY_WIDTH-1:0] a[`KYBER_N],
    input  [`KYBER_POLY_WIDTH-1:0] b[`KYBER_N],
    output [`KYBER_POLY_WIDTH : 0] r[`KYBER_N]
);

  genvar i;
  generate
    for (i = 0; i < 256; i++) begin : g_add
      assign r[i] = a[i] + b[i];
    end
  endgenerate
endmodule
