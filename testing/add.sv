`include "params.vh"
module add (
    input signed [`KYBER_POLY_WIDTH-1:0] a[`KYBER_N],
    input signed [`KYBER_POLY_WIDTH-1:0] b[`KYBER_N],
    output signed [`KYBER_POLY_WIDTH : 0] r[`KYBER_N]
);

  genvar i;
  generate
    for (i = 0; i < 256; i++) begin : g_add
      assign r[i] = a[i] + b[i];
    end
  endgenerate
endmodule
