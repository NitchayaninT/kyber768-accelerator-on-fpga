`include "params.vh"
// *** POST ENCRYPTION MODULE *** //
/*
- Inputs : Ciphertext poly c1, c2 and pre_k (256)  
    - Size : 256*10, 256*10, 256
- Outputs : Ciphertext poly c1, c2 and ss
    - ss : SHAKE256(SHA3-256(Ct), Pre-k)
    - Size : 256 bits
- Enable signals : from Compress encode and pre-encryption (once pre_k is generated)
- Submodules : SHAKE256, SHA3-256
*/
module post_encryption(
    input clk,
    input enable, // when ct input is available
    input prek_enable, // when pre_k input is available
    input rst,
    input  [`KYBER_N - 1:0] pre_k,
    input [7:0]  c1_in [0:959], // 960 bytes
    input [7:0]  c2_in [0:127], // 128 bytes
    output logic [8703:0] ct, // ciphertext stream (c1,c2)
    output logic [`KYBER_N - 1:0] ss, // shared secret
    output reg encrypt_done
);

reg [2:0] phase;
localparam PH_IDLE = 3'd0;
localparam PH_HASH_CT = 3'd1;
localparam PH_GET_SS = 3'd2;
localparam PH_DONE = 3'd3;
logic sha_start, shake_start;
logic [511:0]  ct_prek_reg; // reg before hashing
logic [255:0]  ct_hash_reg; // reg after sha
wire  [255:0]  ct_hashed; // sha output
wire  sha_valid;
wire  shake_done;
wire  [1023:0] shake_out; // output of shake256, but we only need the first 256 bits for ss

assign ss = shake_out[255:0];

always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    phase        <= PH_IDLE;
    sha_start    <= 1'b0;
    shake_start  <= 1'b0;
    ct           <= '0;
    ct_prek_reg  <= '0;
    ct_hash_reg  <= '0;
    encrypt_done <= 1'b0;
  end else begin
    sha_start   <= 1'b0;
    shake_start <= 1'b0;

    case (phase)
      PH_IDLE: begin
        encrypt_done <= 1'b0;
        if (enable) begin
        // 1. pack ct from arrays to raw for easier processing
          integer j;
          for (j=0; j<960; j=j+1) ct[8*j +: 8] <= c1_in[j];
          for (j=0; j<128; j=j+1) ct[8*960 + 8*j +: 8] <= c2_in[j];
          sha_start <= 1'b1;
          phase     <= PH_HASH_CT;
        end
      end

      PH_HASH_CT: begin
        if (sha_valid) begin // hash ct (both c1,c2)
        // 2. SHA256(Ct) -> H(Ct)
          ct_hash_reg <= ct_hashed;
          phase       <= PH_GET_SS;
        end
      end

      PH_GET_SS: begin
        if (prek_enable) begin
        // 3. Combine pre_k with H(Ct)
          ct_prek_reg <= {ct_hash_reg, pre_k}; 
          shake_start <= 1'b1; 
          phase       <= PH_DONE;     
        end
      end

      PH_DONE: begin
        if (shake_done) begin
        // 4. Once SHAKE is finished, module is finished
          encrypt_done <= 1'b1;
        end
      end
    endcase
  end
end

sha3_256 sha3_uut_post_enc (
  .clk(clk),
  .enable(sha_start),
  .in(ct),
  .input_len(8704),
  .output_string(ct_hashed),
  .done(sha_valid)
);

shake256 shake256_uut_post_enc (
  .clk(clk),
  .enable(shake_start),
  .rst(rst),
  .in(ct_prek_reg),
  .input_len(512),
  .nonce(8'h00),
  .output_len(256),
  .output_string(shake_out),
  .done(shake_done)
);
endmodule