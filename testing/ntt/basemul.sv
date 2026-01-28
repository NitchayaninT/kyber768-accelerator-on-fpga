module basemul (
    input clk,
    input start,
    input signed [15:0] a[2],
    input signed [15:0] b[2],
    input signed [15:0] zeta,
    output reg signed [15:0] r[2]
);

  reg fqmul_start;
  reg [1:0] count;
  reg [2:0] fqmul_cycle;
  reg signed [15:0] a1b1;
  reg signed [15:0] a_in[2];
  reg signed [15:0] b_in[2];
  wire signed [15:0] buf_out[2];
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

  reg valid;
  reg add;
  always @(posedge clk) begin
    if (start) begin
      fqmul_cycle <= 0;
      fqmul_start <= 1;
      valid <= 0;
      add <= 0;
      count <= 0;
      // start the computations of the first fqmul
      a_in[0] <= a[0];
      b_in[0] <= b[1];
      // r[1] = fqlmul(a[0], b[1])
      a_in[1] <= a[1];
      b_in[1] <= b[0];
    end else if (!valid) begin
      if (fqmul_cycle < 3) begin
        if (add) begin
          r[1] <= buf_out[0] + buf_out[1];
          add <= 1'b0;
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
            // r[1] = fqlmul(a[0], b[1])
            a_in[1] <= a[1];
            b_in[1] <= b[1];
            fqmul_start <= 1;
            add <= 1;
          end
          1: begin
            a1b1 <= buf_out[1];
            a_in[1] <= a1b1;
            b_in[1] <= zeta;
            fqmul_start <= 1;
          end
          2: begin
            r[0]  <= buf_out[0] + buf_out[1];
            valid <= 1;
          end
        endcase
      end
    end
  end
endmodule
/*
  wire signed [15:0] a1b1;
  wire signed [15:0] a1b1z;
  wire signed [15:0] a0b0;
  fqmul fqmul_a1_b1(.a(a[1]),.b(b[1]), .r(a1b1), .clk(clk),.start(start));
  fqmul fqmul_a1b1_z(.a(a1b1), .b(zeta), .r(a1b1z), .clk(clk), .start(start2));// r[0]  = fqmul(r[0], zeta);
  fqmul fqmul_a0_b0(.a(a[0]), .b(b[0]), .r(a0b0), .clk(clk), .start(start)); //r[0] += fqmul(a[0], b[0]);
  assign r[0] = a0b0 + a1b1z;

  wire signed [15:0] a0b1;
  wire signed [15:0] a1b0;

  fqmul fqmul_a0_b1(.a(a[0]), .b(b[1]), .r(a0b1), .clk(clk), .start(start));
  fqmul fqmul_a1_b0(.a(a[1]), .b(b[0]), .r(a1b0), .clk(clk), .start(start));
  assign r[1] = a0b1 + a1b0;
  */