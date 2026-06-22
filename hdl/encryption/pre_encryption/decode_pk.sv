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
  /*
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
  assign done = 1'b1;*/
  //public_key = 256 + 3 * 3072, which is 32 bytes and 3 384 bytes
  //t0 - t2 each 384 bytes (1152 bytes), rho is 32 bytes
  // total = 1184 bytes
  genvar p, i, b;
  // copy byte 1152 - 1183 to rho
  generate
    for (b = 0; b < 32; b++) begin : G_RHO
      assign rho[255 - 8*b -: 8] = public_key[8*(1152 + b) +: 8];
    end
  endgenerate
  // coeff0 = (byte0 | (byte1 << 8)) & 0xfff;
  // coeff1 = (byte1 >> 4) | (byte2 << 4)  & 0xfff;
  /*byte0:  [ coeff0 bits 0..7 ]

    byte1:  [ coeff1 bits 0..3 ][ coeff0 bits 8..11 ]

    byte2:  [ coeff1 bits 4..11 ]
    every 2 coefficients are packed into 3 bytes
  */
  generate
    for (p = 0; p < KYBER_K; p++) begin : G_POLY
      for (i = 0; i < KYBER_N/2; i++) begin : G_COEFF
        localparam int BASE_BYTE = p*384 + 3*i;

        assign t_trans[p][12*(2*i) +: 12] =
            ({4'b0, public_key[8*(BASE_BYTE+0) +: 8]} |
             ({4'b0, public_key[8*(BASE_BYTE+1) +: 8]} << 8)) & 12'hFFF;

        assign t_trans[p][12*(2*i+1) +: 12] =
            (({4'b0, public_key[8*(BASE_BYTE+1) +: 8]} >> 4) |
             ({4'b0, public_key[8*(BASE_BYTE+2) +: 8]} << 4)) & 12'hFFF;
      end
    end
  endgenerate

  assign done = 1'b1;
endmodule
/* explanation:
  Big-endian:
      first byte goes to high is big endian which is AABBCCDD, 
      this means left side is big. 
  Little-endian:
      first byte goes to low side, which is little endian which is DDCCBBAA, 
      this mean left side is small.
  Official kyber:
    pk byte order = t packed bytes first, rho last
    pk[0], pk[1], pk[2], ..., pk[1183]
    first 1152 bytes are t_vec(0-1151), last 32 bytes are rho(1152 - 1183)
    pk = t0 || t1 || t2 || rho
  In my testbench:(little endian)
    public_key[8*i +: 8] = pk_mem[i];
      low bits                              high bits
      t0                t1        t2        rho
  Python hex string:(big-endian)
    public_key = 9472'h<t0 t1 t2 rho>;
      high bits                             low bits
      t0                t1        t2        rho
        public_key high bits = t0
        public_key low bits  = rho -> assign rho = public_key[255:0];
*/
  

    
    



    
    
    