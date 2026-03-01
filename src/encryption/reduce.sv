/*
Reduce module
Applies Barrett reduction to all coefficients of a polynomial
Inputs : Polynomial u (3x1),v (1)
Outputs: Reduced polynomial u,v

From C reference :
poly_reduce : Applies Barrett reduction to all coefficients of a polynomial

void poly_reduce(poly *r)
{
  unsigned int i;
  for(i=0;i<KYBER_N;i++)
    r->coeffs[i] = barrett_reduce(r->coeffs[i]);
}

int16_t barrett_reduce(int16_t a) {
  int16_t t;
  const int16_t v = ((1U << 26) + 3329 / 2) / 3329;

  t = (int32_t)v * a >> 26;
  t *= 3329;
  return a - t;
}

Operations
- u = u mod q
- v = v mod q
*/
`timescale 1ns / 1ps
module reduce (
    input clk,
    input rst,
    input enable,
    input [15:0] u[0:2][0:255],  // 3 polynomials of degree 256
    input [15:0] v[0:255],  // 1 polynomial of degree 256
    output reg reduce_done,
    output reg [15:0] u_reduced[0:2][0:255],
    output reg [15:0] v_reduced[0:255]
);
  // Barrett reduction function
  // Fast way of computing a mod q because it only involves multiplication and bit-shifting, not division
  // Input: 16 bits signed integer a (from C definition)
  // Output: a mod 3329
  function automatic logic signed [15:0] barrett_reduce(input logic signed [15:0] a);
    localparam int Q = 3329;

    // v = (2^26 + 3329/2)/3329 == 20159 for Q=3329
    localparam int V = 20159;
    logic signed [31:0] mul;
    logic signed [15:0] t;
    logic signed [31:0] q_est;  // estimated quotient (after >> 26)

    begin
      mul = V * a;  // t = V * a (32 bits)
      q_est = mul >>> 26;  // arithmetic shift
      t = q_est * Q;  // t = q_est * Q
      barrett_reduce = a - t;  // return a - t
    end
  endfunction

  integer i, j;
  always @(posedge clk) begin
    if (rst) begin
      reduce_done <= 1'b0;
      for (i = 0; i < 3; i = i + 1) begin
        for (j = 0; j < 256; j = j + 1) begin
          u_reduced[i][j] <= 16'd0;
        end
      end
      for (j = 0; j < 256; j = j + 1) begin
        v_reduced[j] <= 16'd0;
      end
    end else if (enable) begin
      // Reduce u
      for (i = 0; i < 3; i = i + 1) begin
        for (j = 0; j < 256; j = j + 1) begin
          u_reduced[i][j] <= barrett_reduce(u[i][j]);
        end
      end
      // Reduce v
      for (j = 0; j < 256; j = j + 1) begin
        v_reduced[j] <= barrett_reduce(v[j]);
      end
      reduce_done <= 1'b1;
    end else begin
      reduce_done <= 1'b0;
    end
  end
endmodule

