`timescale 1ns / 1ps
`include "params.vh"

module decode_pk_tb;
  reg [(`KYBER_N)+(`KYBER_K * `KYBER_R_WIDTH * `KYBER_N)-1 : 0] public_key;
  wire [`KYBER_N - 1 : 0] rho;
  wire [(`KYBER_R_WIDTH * `KYBER_N) - 1 : 0] t_trans[3];

  decode_pk uut (
      .public_key(public_key),
      .rho(rho),
      .t_trans(t_trans)
  );
  reg [(`KYBER_N)+(`KYBER_K * `KYBER_R_WIDTH * `KYBER_N)-1 : 0] sample_pk[0:4];
  initial begin
    $readmemh("sample_pk.hex", sample_pk);
    $monitor("Public_key:%h\nrho: %h\nt0: %h\nt1: %h\nt2: %h\n", public_key, rho,
             t_trans[0], t_trans[1], t_trans[2]);
    #(`DELAY) public_key = sample_pk[0];
    #(`DELAY) public_key = sample_pk[1];
    #(`DELAY) public_key = sample_pk[2];
    #(`DELAY) public_key = sample_pk[3];
    #(`DELAY) public_key = sample_pk[4];
    #(`DELAY) $finish;
  end
endmodule
