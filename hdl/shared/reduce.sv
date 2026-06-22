/*
Reduce module
Applies Barrett reduction to all coefficients of a polynomial
This module can be used in both encryption and decryption modes, depending on the input polynomial.

MODES 
- Encryption
    Inputs : Polynomial u (3x1),v (1)
    Outputs: Reduced polynomial u,v (within polynomial ring Rq)
- Decryption
    Input : Polynomial from subtraction b
    Output : Reduced polynomial b (within polynomial ring Rq)

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

Problem: 
- it consumes 100000+ resources, way more than noise and matrix gen

Optimization
- use 1 coeff / cycle instead of 4 polys/cycle (now)
- the current design tried to compute 1024 coeff (from 4 poly) barrett reductions in 1 clk
- for optimization, it should instead process index from 0-255 and output each coefficient into output_poly[index]
- this way, only 1 coeff will be processed per cycle, which improves efficiency
*/
`timescale 1ns / 1ps
module reduce#(
    parameter int N = 256,
    parameter int Q = 3329,
    parameter int V = 20159 //v = (2^26 + 3329/2)/3329 == 20159 for Q=3329
)(
    input clk,
    input rst,
    input enable,
    input logic [15:0] in_poly [0:N-1],
    output logic busy,
    output reg reduce_done,
    output logic [11:0] out_poly [0:N-1]
);
    logic signed [15:0] poly_buf [0:N-1];
    logic [7:0] idx; // index counter (0-255)

    // Barrett reduction function
    // Fast way of computing a mod q because it only involves multiplication and bit-shifting, not division
    // Input: 16 bits signed integer a (from C definition)
    // Output: a mod 3329
    function automatic logic signed [15:0] barrett_reduce(input logic signed [15:0] a);
        logic signed [31:0] mul;
        logic signed [15:0] t;
        logic signed [31:0] q_est; // estimated quotient (after >> 26)
        logic signed [31:0] result;
        begin
            mul = V * a; // t = V * a (32 bits)
            q_est = mul >>> 26; // arithmetic shift
            t = q_est * Q; // t = q_est * Q
            result = a - t; // return a - t
            barrett_reduce = result[15:0];
        end
    endfunction

    typedef enum logic [1:0] {IDLE, LOAD, RUN, FINISH} state_t;
    state_t state;

    integer i;
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            busy  <= 1'b0;
            reduce_done <= 1'b0;
            idx <= '0;
            for (i = 0; i < N; i++) begin
                poly_buf[i] <= '0;
                out_poly[i] <= '0;
            end
        end else begin
            reduce_done <= 1'b0; 
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    idx  <= '0;
                    if (enable) begin
                        state <= LOAD;
                        busy  <= 1'b1;
                    end
                end
                // Load input polynomial into poly buffer (1 cycle)
                LOAD: begin
                    for (i = 0; i < N; i++) begin
                        poly_buf[i] <= in_poly[i];
                    end
                    idx   <= '0;
                    state <= RUN;
                end

                // 1 coefficient per cycle
                RUN: begin
                    out_poly[idx] <= barrett_reduce(poly_buf[idx]);

                    if (idx == N-1) begin
                        state <= FINISH;
                    end else begin
                        idx <= idx + 1;
                    end
                end

                FINISH: begin
                    reduce_done  <= 1'b1; // 1-cycle pulse
                    busy  <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule