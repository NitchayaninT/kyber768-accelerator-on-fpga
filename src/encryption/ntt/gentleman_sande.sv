import params_pkg::*;

// **************************************************
// gs butterfly module implement this part of c-reference
// inv_ntt function
//
//        r[j + len] = t - r[j + len];
//        r[j + len] = fqmul(zeta, r[j + len]);
// **************************************************
module gentleman_sande (
    input clk,
    input enable,
    input reset,
    input [KYBER_POLY_WIDTH - 1 : 0] a,  // receive t (actually is r[j] or ram_read_data_a)
    input [KYBER_POLY_WIDTH - 1 : 0] b,
    output [KYBER_POLY_WIDTH -1 : 0] out0,
    output [KYBER_POLY_WIDTH -1 : 0] out1,
    output valid
);

  always_comb begin
  end
endmodule
