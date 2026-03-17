// -- COMPRESS ENCODE for Decryption --
/*
Convert polynomial to a 32-byte message
Description : Use roundq () function to round the polynomial b back to plaintext message m
- Input : b (1 poly, 256 coeffs, 12 bits each)
- Output : m (256 bits stream)

Process
- m' = Roundq(b) = roundq(v' - s_transpose * u') where roundq() is defined as (b[i] + q/2) / q
- This is essentially a quantization step that maps the polynomial coefficients back to bits (0 or 1) 
based on whether they are closer to 0 or q/2 in the modular space defined by q.   

In C:
void poly_tomsg(uint8_t msg[KYBER_INDCPA_MSGBYTES], poly *a)
{
  unsigned int i,j;
  uint16_t t;

  poly_csubq(a);

  for(i=0;i<KYBER_N/8;i++) {
    msg[i] = 0;
    for(j=0;j<8;j++) {
      t = ((((uint16_t)a->coeffs[8*i+j] << 1) + KYBER_Q/2)/KYBER_Q) & 1;
      msg[i] |= t << j;
    }
  }
}

*/
import params_pkg::*;
module compress_encode_dec (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic [KYBER_RQ_WIDTH-1:0] b[0:KYBER_N-1],
    output logic [(KYBER_N)-1:0] m,
    output logic done
);

  function automatic logic roundq(input logic [KYBER_RQ_WIDTH-1:0] coeff);
    logic [15:0] t;
    begin
      t = ({4'b0, coeff} << 1) + (KYBER_Q / 2);
      roundq = (t / KYBER_Q) & 1'b1;
    end
  endfunction

  integer i;

  always_ff @(posedge clk) begin
    if (rst) begin
      m    <= '0;
      done <= 1'b0;
    end else begin
      done <= 1'b0;
      if (enable) begin
        for (i = 0; i < KYBER_N; i++) begin
          m[i] <= roundq(b[i]);
        end
        done <= 1'b1;
      end
    end
  end
endmodule
