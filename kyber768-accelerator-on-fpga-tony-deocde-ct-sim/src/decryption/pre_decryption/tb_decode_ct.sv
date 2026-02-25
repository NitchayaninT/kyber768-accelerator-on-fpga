`timescale 1ns/1ps

module tb_decode_ct;

  logic clk = 0, rst = 1, enable = 0;
  always #5 clk = ~clk;

  logic [7:0]  c1 [0:959];
  logic [7:0]  c2 [0:127];
  logic [15:0] u  [0:2][0:255];
  logic [15:0] v  [0:255];
  logic        decompress_done;

  // temp memories for iverilog
  logic [7:0] c1_mem [0:959];
  logic [7:0] c2_mem [0:127];
  // golden refs (1-D each)
  logic [15:0] u0_ref [0:255];
  logic [15:0] u1_ref [0:255];
  logic [15:0] u2_ref [0:255];
  logic [15:0] v_ref  [0:255];

  decode_ct dut (
    .enable(enable),
    .rst(rst),
    .clk(clk),
    .c1(c1),
    .c2(c2),
    .u(u),
    .v(v),
    .decompress_done(decompress_done)
  );

  int i;
  int errors;

  initial begin
    // ---------------- LOAD INPUTS ----------------
    $readmemh("c1.mem", c1_mem);
    $readmemh("c2.mem", c2_mem);

    for (i = 0; i < 960; i++) c1[i] = c1_mem[i];
    for (i = 0; i < 128; i++) c2[i] = c2_mem[i];
    $readmemh("u0_ref.mem", u0_ref);
    $readmemh("u1_ref.mem", u1_ref);
    $readmemh("u2_ref.mem", u2_ref);
    $readmemh("v_ref.mem",  v_ref);


    // ---------------- RESET ----------------
    rst = 1;
    repeat (3) @(posedge clk);
    rst = 0;

    // ---------------- START ----------------
    @(negedge clk);
    enable = 1;
    @(negedge clk);
    enable = 0;

    // ---------------- WAIT DONE ----------------
    wait (decompress_done);
    repeat (2) @(posedge clk);

    $display("\n============= DECOMPRESS DONE =============");
    for (i=0; i<256; i++) begin
      if (u[0][i] !== u0_ref[i]) begin
        $display("MISMATCH u0[%0d] got=%h exp=%h", i, u[0][i], u0_ref[i]);
        errors++;
        if (errors == 10) $fatal(1, "Too many mismatches");
      end
      if (u[1][i] !== u1_ref[i]) begin
        $display("MISMATCH u1[%0d] got=%h exp=%h", i, u[1][i], u1_ref[i]);
        errors++;
        if (errors == 10) $fatal(1, "Too many mismatches");
      end
      if (u[2][i] !== u2_ref[i]) begin
        $display("MISMATCH u2[%0d] got=%h exp=%h", i, u[2][i], u2_ref[i]);
        errors++;
        if (errors == 10) $fatal(1, "Too many mismatches");
      end
    end

    // ---- compare v ----
    for (i=0; i<256; i++) begin
      if (v[i] !== v_ref[i]) begin
        $display("MISMATCH v[%0d] got=%h exp=%h", i, v[i], v_ref[i]);
        errors++;
        if (errors == 10) $fatal(1, "Too many mismatches");
      end
    end

    if (errors == 0) begin
      $display("PASS: decode_ct matches u0/u1/u2/v reference.");
    end else begin
      $display("FAIL: %0d mismatches total.", errors);
      $fatal(1);
    end
    $finish;
  end

endmodule
