`include "params.vh"
`include "decode_pk.sv"
`include "decode_msg.sv"
`include "ntt.sv"

// top module for overall encryption process
// main reference from NIST reference implemetaton
//
module indcpa(
  input [(`KYBER_N)+(`KYBER_K * `KYBER_R_WIDTH * `KYBER_N)-1 : 0] pk,
  input [255:0] msg,
  output [255:0] ct,
  output [255:0] ss
);

    // Comparing to NIST reference implementation
    // rho      : seed
    // t_trans  : pkpv
    // poly_msg : k
    wire [`KYBER_N - 1 : 0] rho;
    wire [(`KYBER_R_WIDTH * `KYBER_N) - 1 : 0] t_trans[3];
    reg [(`KYBER_N * `KYBER_R_WIDTH)-1:0] poly_msg;

    decode_pk dpk(.public_key(pk), .rho(rho), .t_trans);
    decode_msg dmsg(.msg(msg), .poly_msg(poly_msg));

    //---------- Undone ----------
    // gen_at(at, rho);
    // get noise e1, e2, sp
    //----------------------------

    // transform one of the error to NTT form
    ntt(sp, s_ntt);

    //---------- Undone ----------
    // multiplication
    //polyvec_pointwise_acc_montgomery(&bp.vec[i], &at[i], &sp);
    //polyvec_pointwise_acc_montgomery(&v, &pkpv, &sp);
    //----------------------------

    // add()
endmodule
