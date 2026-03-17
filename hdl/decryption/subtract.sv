import params_pkg::*;

module subtract (
    input signed [KYBER_POLY_WIDTH - 1 : 0] a[KYBER_N],
    input signed [KYBER_POLY_WIDTH - 1 : 0] b[KYBER_N],
    output logic signed [KYBER_POLY_WIDTH - 1 : 0] r[KYBER_N]
);

  genvar i;
  generate
    for (i = 0; i < 256; i++) begin : g_sub
      logic signed [KYBER_POLY_WIDTH - 1:0] d;
      always_comb begin
        d = a[i] - b[i];
        if (d < 0) d = d + KYBER_Q;
        r[i] = d[KYBER_POLY_WIDTH-1:0];
      end
    end
  endgenerate
endmodule
