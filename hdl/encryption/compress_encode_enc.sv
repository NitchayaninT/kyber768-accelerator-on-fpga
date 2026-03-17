//** COMPRESS ENCODE **//
/*
Description : Compress ciphertext using rounded function
- Inputs : u,v (polynomials)
- Output : ct = (c1,c2)
    - c1 = 3 polys with coef = du bits (du=10)
    - c2 = 1 poly with coef = dv bits (dv=4)
- Process
    - Compress u to 10 bits per coef -> c1
    - Compress v to 4 bits per coef -> c2
*/

module compress_encode #(
    parameter int Q = 3329
)(
    input  logic enable,
    input  logic rst,
    input  logic clk,
    input  logic [11:0] u [0:2][0:255],   // 3 polys of 256 coeffs
    input  logic [11:0] v [0:255],        // 1 poly of 256 coeffs

    // c1 = 3 * 320 bytes = 960 bytes (du=10)
    // c2 = 128 bytes (dv=4)
    output logic [7:0]  c1 [0:959], // 960 bytes
    output logic [7:0]  c2 [0:127], // 128 bytes
    output logic compress_done
);

  // polyvec u compress to 10 bits (du=10)
  function automatic logic [9:0] compress10(input logic [15:0] a_in);
    logic [15:0] a; //coeff temp
    logic [31:0] num;
    logic [31:0] div;
    begin
      //a = csubq(a_in);
      num = ((a_in << 10) + (Q/2));
      compress10 = (num/Q) & 10'h3ff; // in range 0..1023
    end
  endfunction

  // poly v compress to 4 bits (dv=4)
  function automatic logic [3:0] compress4(input logic [15:0] a_in);
    logic [15:0] a; //coeff temp
    logic [31:0] num;
    logic [31:0] div;
    begin
      //a = csubq(a_in);
      num = ((a_in << 4) + (Q/2));
      compress4 = (num/Q) & 4'hf; // in range 0..15
    end
  endfunction

  // FSM for compress + encode
  typedef enum logic [1:0] {IDLE, DO_C1, DO_C2, DONE} state_t;
  state_t state;

  int poly_i; // 0..2 for u polys
  int blk_j; // number of iterations (blocks)
  // c1: 0..63 (each block packs 4 coeffs -> iterate 5 bytes at a time)
  // c2: 0..31 (each block packs 8 coeffs -> iterate 4 bytes at a time)

  // temporary compressed values
  logic [9:0] t0, t1, t2, t3;
  logic [3:0] s0, s1, s2, s3, s4, s5, s6, s7;

  int base; // byte base index

  always_ff @(posedge clk) begin
    if (rst) begin
      state         <= IDLE;
      poly_i        <= 0;
      blk_j         <= 0;
      compress_done <= 1'b0;
    end else begin
      compress_done <= 1'b0;
      case (state)
        IDLE: begin
          if (enable) begin
            poly_i <= 0;
            blk_j  <= 0;
            state  <= DO_C1;
          end
        end
        // c1 (du=10): 3 polys × 64 blocks (iterations) × 5 bytes = 960 bytes
        // Each block packs coeffs
        // in C Kyber ref:
        // r0 =  t0 >> 0
        // r1 = (t0 >> 8) | (t1 << 2)
        // r2 = (t1 >> 6) | (t2 << 4)
        // r3 = (t2 >> 4) | (t3 << 6)
        // r4 = (t3 >> 2)
        DO_C1: begin
          t0 = compress10(u[poly_i][4*blk_j + 0]);
          t1 = compress10(u[poly_i][4*blk_j + 1]);
          t2 = compress10(u[poly_i][4*blk_j + 2]);
          t3 = compress10(u[poly_i][4*blk_j + 3]);

          base = poly_i*320 + blk_j*5; // 1 poly 320 bytes. iterate 5 bytes at a time

          c1[base+0] <= t0[7:0]; // byte 1
          c1[base+1] <= {t1[5:0], t0[9:8]};  // (t0 >> 8) | (t1 << 2)
          c1[base+2] <= {t2[3:0], t1[9:6]};  // (t1 >> 6) | (t2 << 4)
          c1[base+3] <= {t3[1:0], t2[9:4]};  // (t2 >> 4) | (t3 << 6)
          c1[base+4] <= {t3[9:2]}; // (t3 >> 2)
          // advance to next u poly
          if (blk_j == 63) begin
            blk_j <= 0;
            if (poly_i == 2) begin
              state <= DO_C2;
            end else begin
              poly_i <= poly_i + 1;
            end
          end else begin
            blk_j <= blk_j + 1;
          end
        end
        // c2 (dv=4): 32 blocks(iterations) × 4 bytes = 128 bytes
        // Each block packs 8 coeffs, each coef 4 bits, 8 coef 32 bits -> 4 bytes:
        DO_C2: begin
          s0 = compress4(v[8*blk_j + 0]);
          s1 = compress4(v[8*blk_j + 1]);
          s2 = compress4(v[8*blk_j + 2]);
          s3 = compress4(v[8*blk_j + 3]);
          s4 = compress4(v[8*blk_j + 4]);
          s5 = compress4(v[8*blk_j + 5]);
          s6 = compress4(v[8*blk_j + 6]);
          s7 = compress4(v[8*blk_j + 7]);

          base = blk_j*4; // iterate 4 bytes at a time

          c2[base + 0] <= {s1, s0};
          c2[base + 1] <= {s3, s2};
          c2[base + 2] <= {s5, s4};
          c2[base + 3] <= {s7, s6};

          if (blk_j == 31) begin
            state <= DONE;
          end else begin
            blk_j <= blk_j + 1;
          end
        end

        DONE: begin
          compress_done <= 1'b1;
          state <= IDLE;
        end
        default: state <= IDLE;
      endcase
    end
  end
endmodule