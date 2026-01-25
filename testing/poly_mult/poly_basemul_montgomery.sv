/*************************************************
* Name:        poly_basemul_montgomery
*
* Description: Multiplication of two polynomials in NTT domain
*
* Arguments:   - poly *r:       pointer to output polynomial
*              - const poly *a: pointer to first input polynomial
*              - const poly *b: pointer to second input polynomial
**************************************************/
module poly_basemul_montgomery(
  input clk,enable,
  input [15:0] a [255],
  input [15:0] b [255],
  output [15:0] r [255]
);

// for loop 0 -> 64

  always begin
  end
endmodule

