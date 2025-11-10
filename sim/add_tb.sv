`timescale 1ns / 1ps
`include "params.vh"

module add_tb;
  reg clk;
  reg enable;
  reg rst;
  reg [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] x[3];  // old syntax is x[0:2;
  reg [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] y;
  reg [(`KYBER_N * `KYBER_R_WIDTH)-1:0] msg_poly;
  reg [(`KYBER_N * `KYBER_R_WIDTH) -1 : 0] e_1[3];
  reg [(`KYBER_N * `KYBER_R_WIDTH) -1 : 0] e_2;
  wire [(`KYBER_N * (`KYBER_R_WIDTH + 1)) - 1 : 0] u[3];
  wire [(`KYBER_N * (`KYBER_R_WIDTH + 2)) - 1 : 0] v;
  wire valid;
  wire [2:0] debug_state;

  add uut (
      .clk(clk),
      .enable(enable),
      .rst(rst),
      .x(x),
      .y(y),
      .msg_poly(msg_poly),
      .e_1(e_1),
      .e_2(e_2),
      .u(u),
      .v(v),
      .valid(valid),
      .debug_state(debug_state)
  );

  reg [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] poly[0:4];
  reg [(`KYBER_N * `KYBER_R_WIDTH) -1 : 0] small_poly[0:3];
  initial begin
    $readmemh("add_poly.hex", poly);
    $readmemh("add_small_poly.hex", small_poly);
    x[0] = poly[0];
    x[1] = poly[1];
    x[2] = poly[2];
    y = poly[3];
    msg_poly = poly[4];

    e_1[0] = small_poly[0];
    e_1[1] = small_poly[1];
    e_1[2] = small_poly[2];
    e_2 = small_poly[3];

    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end

  initial begin
    $monitor("%t %b\n in1:%h\nin2:%h\nout:%h", $time, debug_state, uut.in_buf0, uut.in_buf1,
             uut.out_buf);
    $dumpfile("dump.vcd");
    $dumpvars(0, add_tb);

    rst = 1;
    enable = 0;
    #(`DELAY * 1);
    rst = 0;
    #(`DELAY);
    enable = 1;

    // Wait for computation to complete
    wait (valid == 1);

    #(`DELAY * 2);
    $display("Computation completed at time %t", $time);

    // Display results
    $display("\nu[0]:%h\nu[1]:%h\nu[2]:%h\nv:%h", u[0], u[1], u[2], v);

    $finish;
  end
endmodule
