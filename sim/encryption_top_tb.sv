`timescale 1ns / 1ps
`define DELAY 2;
import params_pkg::*;

module encrytion_top_tb;
  logic clk, rst, start;
  logic [KYBER_N -1 : 0] r_in;
  logic [(KYBER_N)+(KYBER_K * KYBER_RQ_WIDTH * KYBER_N)-1:0] encryption_key; // public key from keygen
  logic [KYBER_N - 1:0] pre_k;  // pre-k for post-decryption
  logic [KYBER_N - 1:0] ss1;
  logic [(1088*8)-1:0] ct_out;  // 128 bytes for c2
  logic encrypt_done;  // DONE WITH ENCRYPTION

  encryption_top encryption_top (
      .clk           (clk),
      .rst           (rst),
      .start         (start),
      .r_in          (r_in),
      .encryption_key(encryption_key),
      .pre_k         (pre_k),
      .ss1           (ss1),
      .ct_out        (ct_out),
      .encrypt_done  (encrypt_done)
  );

  always #1 clk = !clk;

  initial begin
    clk = 0;
  end
endmodule
