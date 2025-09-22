// -------------------------------------------------
// after reconsider the purpose of this module why do we even have it in the
// first place?
// we can just connnect the output of the pre_encryption to other module
// rho -> hash sampling and rejection modules
// Transpose mean nothing in digital logic it is the same storage but connect
// to different place
`include "params.vh"

// This module is combinational circuit
module decode_pk (
    input wire [(KYBER_N)+(KYBER_K * KYBER_R_WIDTH * KYBER_N)-1 : 0] public_key,
    output wire [KYBER_N - 1 : 0] rho,
    output wire [(KYBER_R_WIDTH * KYBER_N) - 1 : 0] t_trans[3]
);

  // Noted that concept of transpose in FPGA does not make much sense since we
  // just save in the net variables just wire differently

  assign rho = public_key[255:0];
  // generate block for t_trans
  genvar i;
  generate
    for (i = 0; i < 3; i++) begin : g_unpack
      assign t_trans[i] = public_key[
        256 + i*(KYBER_K * KYBER_R_WIDTH * KYBER_N) +: (KYBER_K * KYBER_R_WIDTH * KYBER_N)
      ];
    end
  endgenerate
endmodule
