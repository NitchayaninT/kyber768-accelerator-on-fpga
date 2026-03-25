`timescale 1ns / 1ps

import params_pkg::*;

module post_decryption(
    input clk,
    input enable, // when m_prime input is available
    input prek_enable, // when pre_k input is available from compress encode
    input rst,
    input [KYBER_N-1:0] m_prime,
    input [KYBER_N-1:0] pre_k,
    input  logic [8703:0] ct,
    input logic[KYBER_N-1:0]coin,
    input logic [(KYBER_N * KYBER_RQ_WIDTH * KYBER_K)+KYBER_N-1:0] PK,
    output reg f,
    output logic [KYBER_N-1:0] ss,
    output reg decrypt_done
);
reg [2:0] phase;
localparam PH_IDLE = 3'd0;
localparam PH_SHA512 = 3'd1;
localparam PH_ENCRYPT = 3'd2;
localparam PH_VERIFY = 3'd3;
localparam PH_SHA256 = 3'd4;
localparam PH_DONE = 3'd5;
//(c', pre−k') =SHA512(pre−k, m')
logic [511:0]  m_prek_reg; // reg before hashing, we concat pre-k and m'
wire [511:0]  m_prek_hashed;//wire out the output
// the hashed result in c_prime and pre_k_prime
logic [255:0] c_prime;
logic [255:0] pre_k_prime;
//encrypt again, the output is ct_prime
wire [8703:0] ct_prime_output;
logic [8703:0] ct_prime;
//check if false or true by comparing ct_prime and ct
//if true, ss = SHAKE265(SHA256(Ct),coin)
//false, ss = SHAKE265(SHA256(Ct),pre_k_prime)
logic [511:0]  ct_coin_reg;
wire [255:0]  ct_hashed;

logic sha256_start,sha512_start,encryption_start,shake_start;
wire  sha256_valid,sha512_valid,encrypt_valid;
wire  shake_done;
wire  [1023:0] shake_out;

assign ss = shake_out[255:0];
always_ff @(posedge clk or posedge rst) begin
    if(rst)begin
        phase <= PH_IDLE;
        sha512_start <= 1'b0;
        sha256_start <= 1'b0;
        shake_start <= 1'b0;
        encryption_start <= 1'b0;
        f <= 0;
        decrypt_done <= 0;
        m_prek_reg <= 0;
        ct_prime <= 0;
        pre_k_prime <= '0;
        c_prime     <= '0;
        ct_coin_reg <= '0;
    end else begin
        sha512_start <= 1'b0;
        sha256_start <= 1'b0;
        shake_start <= 1'b0;
        encryption_start <= 1'b0;
        case(phase)
            PH_IDLE:begin
                decrypt_done<=0;
                if(enable&&prek_enable)begin
                    m_prek_reg <= {pre_k,m_prime};
                    sha512_start <= 1'b1;
                    phase <= PH_SHA512;
                end
            end
            PH_SHA512:begin
                if (sha512_valid) begin
                    pre_k_prime <=  m_prek_hashed[(KYBER_N-1):0];
                    c_prime <= m_prek_hashed[(2*KYBER_N)-1:KYBER_N];
                    encryption_start <= 1'b1;
                    phase <= PH_ENCRYPT;
                end
            end
            PH_ENCRYPT:begin
                if (encrypt_valid) begin
                    ct_prime <= ct_prime_output;
                    phase <= PH_VERIFY;
                end
            end
            PH_VERIFY:begin
                f <= (ct_prime == ct);
                sha256_start <= 1'b1;
                phase <= PH_SHA256;
            end
            PH_SHA256:begin
                if (sha256_valid) begin
                    if(f==1'b1)begin
                        ct_coin_reg <= {ct_hashed,pre_k_prime};//true
                    end else begin
                        ct_coin_reg <= {ct_hashed,coin}; //false   
                    end
                    shake_start <= 1'b1;
                    phase <= PH_DONE;
                end
            end
            PH_DONE:begin
                if(shake_done)begin
                    decrypt_done<=1;
                   // phase <= PH_IDLE;
                end
            end
        endcase
    end
end
encryption_top encrypt_post_dec(
    .clk(clk),
    .rst(rst),
    .start(encryption_start),
    .r_in(),
    .encryption_key(PK),
    .m_prime(m_prime),
    .c_prime(c_prime),
    .mode(1),
    .pre_k(),
    .ss1(),
    .ct_out(ct_prime_output),
    .encrypt_done(encrypt_valid)
);
sha3_512 sha3_512_uut_post_dec (
  .clk(clk),
  .enable(sha512_start),
  .in(m_prek_reg),
  .input_len(512),
  .output_string(m_prek_hashed),
  .done(sha512_valid)
);
sha3_256 sha3_256_uut_post_dec (
  .clk(clk),
  .enable(sha256_start),
  .in(ct),
  .input_len(8704),
  .output_string(ct_hashed),
  .done(sha256_valid)
);

shake256 shake256_uut_post_dec (
  .clk(clk),
  .enable(shake_start),
  .rst(rst),
  .in(ct_coin_reg),
  .input_len(512),
  .nonce(8'h00),
  .output_len(256),
  .output_string(shake_out),
  .done(shake_done)
);
endmodule