// -------------------------------------------------
// rho -> hash sampling and rejection modules
// Transpose mean nothing in digital logic it is the same storage but connect
// to different place
import params_pkg::*;
// This module is combinational circuit
module decode_pk (
    input wire [(KYBER_N)+(KYBER_K * KYBER_RQ_WIDTH * KYBER_N)-1 : 0] public_key,
    output wire [KYBER_N - 1 : 0] rho,
    output wire [(KYBER_RQ_WIDTH * KYBER_N) - 1 : 0] t_trans[3],
    output wire done
);
  // Noted that concept of transpose in FPGA does not make much sense since we
  // just save in the net variables just wire differently
  assign rho = public_key[255:0];
  // generate block for t_trans
  wire [(KYBER_RQ_WIDTH * KYBER_N)-1:0] t_raw[3];

  // before reorder
  genvar i;
  generate
    for (i = 0; i < KYBER_K; i++) begin : G_UNPACK
      assign t_raw[i] = public_key[256+i*(KYBER_RQ_WIDTH*KYBER_N)+:(KYBER_RQ_WIDTH*KYBER_N)];
    end
  endgenerate

  // Reverse bytes inside each polynomial (3072 bits = 384 bytes)
  localparam int T_BYTES = (KYBER_RQ_WIDTH * KYBER_N) / 8;  // 384

  wire [3071:0] t_reordered[3];

  genvar p, b;
  generate
    for (p = 0; p < 3; p++) begin
      for (b = 0; b < T_BYTES; b++) begin
        assign t_reordered[p][b*8+:8] = t_raw[p][(T_BYTES-1-b)*8+:8];
      end
    end
  endgenerate

  assign t_trans[0] = t_reordered[2];
  assign t_trans[1] = t_reordered[1];
  assign t_trans[2] = t_reordered[0];
  assign done = 1'b1;
endmodule
