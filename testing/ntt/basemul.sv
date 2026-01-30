`include "params.vh"
module basemul (
    input clk,
    input basemul_start,
    input signed [`KYBER_POLY_WIDTH - 1:0] a[2],
    input signed [`KYBER_POLY_WIDTH - 1:0] b[2],
    input signed [`KYBER_POLY_WIDTH - 1:0] zeta,
    output reg signed [`KYBER_POLY_WIDTH - 1:0] r[2],
    output reg r0_valid,
    output reg r1_valid
);

  reg fqmul_start;
  reg [1:0] count;
  reg [2:0] fqmul_cycle;
  reg signed [`KYBER_POLY_WIDTH - 1:0] a1b1;
  reg signed [`KYBER_POLY_WIDTH - 1:0] a_in[2];
  reg signed [`KYBER_POLY_WIDTH - 1:0] b_in[2];
  wire signed [`KYBER_POLY_WIDTH - 1:0] buf_out[2];
  genvar g;
  generate
    for (g = 0; g < 2; g++) begin : g_fqmul
      fqmul fqmul_uut (
          .clk(clk),
          .start(fqmul_start),
          .a(a_in[g]),
          .b(b_in[g]),
          .r(buf_out[g])
      );
    end
  endgenerate

  reg add;
  always @(posedge clk) begin
    if (basemul_start) begin
      a_in <= a;
      b_in <= b;
      fqmul_cycle <= 0;
      r0_valid <= 0;
      r1_valid <= 0;
      add <= 0;
      count <= 0;
      fqmul_start <= 1;
      // start the computations of the first fqmul
      a_in[0] <= a[0];
      b_in[0] <= b[1];
      a_in[1] <= a[1];
      b_in[1] <= b[0];
    end else if (!r0_valid) begin
      if (fqmul_cycle < 3) begin
        if (add) begin
          r[1] <= buf_out[0] + buf_out[1];
          add <= 1'b0;
          r1_valid <= 1;
        end
        fqmul_start <= 0;
        //this if else block for watiting for fqmul to compute
        fqmul_cycle <= fqmul_cycle + 1;
      end else if (fqmul_cycle == 3) begin
        fqmul_cycle <= 0;
        count <= count + 1;
        unique case (count)
          0: begin
            a_in[0] <= a[0];
            b_in[0] <= b[0];
            a_in[1] <= a[1];
            b_in[1] <= b[1];
            fqmul_start <= 1;
            add <= 1;
          end
          1: begin
            // here is the bug when i update the value
            a1b1 <= buf_out[1];
            a_in[1] <= buf_out[1];
            b_in[1] <= zeta;
            fqmul_start <= 1;
          end
          2: begin
            r[0] <= buf_out[0] + buf_out[1];
            r0_valid <= 1;
          end
        endcase
      end
    end
  end
endmodule
