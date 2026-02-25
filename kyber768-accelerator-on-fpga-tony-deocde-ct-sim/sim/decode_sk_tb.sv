`timescale 1ns / 1ps
`include "params.vh"

module decode_sk_tb;
  reg [(`KYBER_N * `KYBER_R_WIDTH * `KYBER_K) //decryption key s
      + 256 + (`KYBER_N * `KYBER_R_WIDTH * `KYBER_K)// encapsulation key
      +(2*`KYBER_N)- 1 : 0] in;  // pre-k, coin
  wire [(`KYBER_N * `KYBER_R_WIDTH)-1:0] out[0:2];  // decryption key s

  reg [(`KYBER_N * `KYBER_R_WIDTH * `KYBER_K) //decryption key s
      + 256 + (`KYBER_N * `KYBER_R_WIDTH * `KYBER_K)// encapsulation key
      +(2*`KYBER_N)- 1 : 0] mem [0:4];  // pre-k, coin
  decode_sk uut(
    .in(in),
    .out(out)
  );

  initial begin
    $monitor("secret_key:%h\ns[0]=%h\ns[1]=%h\ns[2]=%h\n",in,out[0],out[1],out[2]);
    $readmemh("secret_key.hex", mem);
    #(`DELAY) in = mem[0];
    #(`DELAY) in = mem[1];
    #(`DELAY) in = mem[2];
    #(`DELAY) in = mem[3];
    #(`DELAY) in = mem[4];
    #(`DELAY * 2) $finish;
  end
endmodule
