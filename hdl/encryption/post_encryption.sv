import params_pkg::*;
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
    input [KYBER_N - 1:0] pre_k,
    input [7:0]  c1_in [0:959], // 960 bytes
    input [7:0]  c2_in [0:127], // 128 bytes
    input  logic hash_valid,
    input  logic [5375:0] hash_message_out,
    output logic [8703:0] ct, // ciphertext stream (c1,c2)
    output logic [KYBER_N - 1:0] ss, // shared secret
    output logic hash_start,
    output logic [1:0]  hash_mode,
    output logic [15:0] hash_input_length,
    output logic [15:0] hash_output_length,
    output logic [9471:0] hash_message_in,
    output reg encrypt_done
);

reg [2:0] phase;
localparam PH_IDLE      = 3'd0;
localparam PH_PACK_CT   = 3'd1;
localparam PH_HASH_CT   = 3'd2;
localparam PH_GET_SS    = 3'd3;
localparam PH_WAIT_SS   = 3'd4;
localparam PH_DONE      = 3'd5;
logic [8703:0] ct_hash_input;
logic [511:0]  ct_prek_reg; // reg before hashing
logic [255:0]  ct_hash_reg; // reg after sha
wire  [255:0]  ct_hashed; // sha output
logic [255:0]  shake_out; // shake output
wire  hash_valid;

genvar ss_b;
generate // reverse order for better visualization to compare with C
  for (ss_b = 0; ss_b < 32; ss_b = ss_b + 1) begin : SS_OUTPUT_ORDER
    assign ss[8*(31-ss_b) +: 8] = shake_out[8*ss_b +: 8];
  end
endgenerate

always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    phase        <= PH_IDLE;
    hash_start    <= 1'b0;
    ct           <= '0;
    ct_hash_input <= '0;
    ct_prek_reg  <= '0;
    ct_hash_reg  <= '0;
    encrypt_done <= 1'b0;
  end else begin
    hash_start <= 1'b0;
    case (phase)
      PH_IDLE: begin
        encrypt_done <= 1'b0;
        if (enable) begin
        // 1. pack ct from arrays to raw for easier processing
          integer j;
          for (j=0; j<960; j=j+1) begin
            ct_hash_input[8*j +: 8] <= c1_in[j];
            ct[8*(1087-j) +: 8] <= c1_in[j];
          end
          for (j=0; j<128; j=j+1) begin
            ct_hash_input[8*960 + 8*j +: 8] <= c2_in[j];
            ct[8*(127-j) +: 8] <= c2_in[j];
          end
          phase <= PH_PACK_CT;
        end
      end

      PH_PACK_CT: begin
          hash_start <= 1'b1; // start hashing ct right after packing is done
          hash_mode <= 2'b00; // SHA3-256
          hash_input_length <= 16'd8704; // 8704 bits = 1088 bytes = c1+c2
          hash_output_length <= 16'd256; // output length in bits
          hash_message_in <= ct_hash_input;
          phase <= PH_HASH_CT;
      end

      PH_HASH_CT: begin
        if (hash_valid) begin // hash ct (both c1,c2)
        // 2. SHA256(Ct) -> H(Ct)
          ct_hash_reg <= hash_message_out[255:0];
          phase       <= PH_GET_SS;
        end
      end

      PH_GET_SS: begin
        if (prek_enable) begin
        // 3. Combine pre_k with H(Ct)
          ct_prek_reg <= {ct_hash_reg, pre_k};
          phase       <= PH_WAIT_SS;     
        end
      end
      
      PH_WAIT_SS: begin
        hash_start <= 1'b1;
        hash_mode <= 2'b11; // SHAKE256
        hash_input_length <= 16'd512;
        hash_output_length <= 16'd256;
        hash_message_in <= '0;
        hash_message_in[511:0] <= ct_prek_reg;
        phase <= PH_DONE;
      end
      PH_DONE: begin
        if (hash_valid) begin
          shake_out <= hash_message_out[255:0];
        // 4. Once SHAKE is finished, module is finished
          encrypt_done <= 1'b1;
        end
      end
    endcase
  end
end

/*hash_controller sha3_uut_post_enc (
  .clk(clk),
  .rst(rst),
  .enable(hash_start),
  .hash_mode(2'b00), // sha3-256 mode
  .input_length(16'd8704), // 8704 bits = 1088 bytes = c1+c2
  .output_length(16'd256), // output length in bits
  .message_in(ct_hash_input),
  .message_out(ct_hashed),
  .valid(hash_valid)
);

 hash_controller shake256_uut_post_enc (
  .clk(clk),
  .enable(shake_start),
  .rst(rst),
  .hash_mode(2'b11), // shake256 mode
  .input_length(16'd512), // 512 bits = ct_hash + pre_k
  .output_length(16'd256), // output length in bits
  .message_in(ct_prek_reg),
  .message_out(shake_out),
  .valid(shake_done)
);*/

endmodule
