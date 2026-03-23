// POST INDCPA DECRYPTION MODULE
/*
Re-Encrypt the plain text message again and compare new and received ciphertext
Input : 
- message 256 bits (32 bytes)
- pre_k 256 bits (32 bytes)
- ciphertext c1,c2 (960 bytes + 128 bytes) = 1088 bytes from post-encryption
    - 7680 bits for c1 (3 polys) = 960 bytes
    - 1024 bits for c2 (1 poly) = 128 bytes

Output :
If Ct=Ct', output
- shared secret 256 bits (32 bytes), ss= shake256(sha3-256(Ct), coin)
- boolean true/false after comparing with enc's Ct

If Ct!=Ct', output
- FAKE shared secret 256 bits (32 bytes) = shake256(SHA3-256(ct), pre-k)
- boolean false

Process :
1. (c', pre-k') = SHA3-512(pre-k, m)
2. Ct' = IND-CPA-KyberEncryption(m',PK,c'), from decode PK to after post-encryption

IND-CPA-KyberEncryption(m',PK,c'): 
    1. Decode PK to get rho
    2. Decode msg to get msg poly
    3. Generate noise polynomials using c' as seed
    4. Generate matrix A from PK
    5. Main computation to get Ct' = (u', v'):
    6. Reduce, Compress encode, post-enc
    7. Output Ct' = (u', v') with coef 10 bits for u' and coef 4 bits for v'
    8. Compare Ct' with received Ct, if they are the same, 
    output shared secret = shake256(sha3-256(Ct), coin), else output shared secret = shake256(SHA3-256(ct), pre-k)
*/
import params_pkg::*;
module post_decryption (
    input clk,
    input rst,
    input enable,
    input [KYBER_N-1:0] msg,  // msg from compress encode
    input [(KYBER_N)+(KYBER_K * KYBER_RQ_WIDTH * KYBER_N)-1:0] encryption_key, // PK from pre-encryption
    input [KYBER_N - 1:0] pre_k,  // pre-k from pre-decryption
    input [(1088*8)-1:0] ct,  // ct from encryption
    output reg [KYBER_N - 1:0] ss,
    output logic ct_match,  // boolean true/false after comparing with enc's Ct
    output reg valid
);

  reg [KYBER_N-1:0] c_prime;
  reg [KYBER_N-1:0] pre_k_prime;
  reg [(KYBER_RQ_WIDTH * KYBER_N)-1:0] msg_poly;
  reg [KYBER_N - 1:0] rho;
  reg [(KYBER_N * KYBER_RQ_WIDTH)-1:0] t_vec[3];
  reg [KYBER_POLY_WIDTH-1 : 0] a_t[0:(KYBER_K*KYBER_K)-1][0:KYBER_N-1];
  reg [KYBER_POLY_WIDTH-1:0] e2[0:KYBER_N-1];
  reg [KYBER_POLY_WIDTH-1:0] e1[0:KYBER_K-1][0:KYBER_N-1];
  reg [KYBER_POLY_WIDTH-1:0] r[0:KYBER_K-1][0:KYBER_N-1];
  reg sha3_valid;
  reg public_matrix_valid;
  reg public_matrix_done;
  reg noise_gen_valid;
  reg noise_done;

  // 1. (c', pre-k') = SHA3-512(pre-k, m)
  sha3_512 sha3_512_uut (
      .clk(clk),
      .enable(enable),
      .rst(rst),
      .in({pre_k, msg}),  // 512 bit input
      .input_len(512),
      .output_string({c_prime, pre_k_prime}),  // 512 bit output
      .done(noise_gen_valid)
  );

  // 2. Ct' = IND-CPA-KyberEncryption(m',PK,c'), from decode PK to after post-encryption
  decode_msg dmsg_uut (
      .msg(msg),
      .poly_msg(msg_poly)
  );
  decode_pk dpk_uut (
      .public_key(encryption_key),
      .rho(rho),
      .t_trans(t_vec),
      .done(public_matrix_valid)
  );
  public_matrix_gen pmg_uut (
      .clk(clk),
      .rst(rst),
      .enable(public_matrix_valid),
      .seed(rho),
      .public_matrix_done(public_matrix_done),
      .public_matrix_poly_index(),
      .public_matrix_poly_valid(),
      .A(a_t)
  );

  noise_gen ng_uut (
      .clk(clk),
      .rst(rst),
      .enable(noise_gen_valid),  // can start noise gen after getting c' and pre-k'
      .coin(c_prime),  // use c' as seed for noise gen
      .e2(e2),
      .e1(e1),
      .r(r),
      .noise_done(noise_done)
  );
  // Main computation
endmodule

