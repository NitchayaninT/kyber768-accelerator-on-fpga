`define NTT_OMEGA 17
module ntt (
    input enable,
    input clk,
    input signed [15:0] in [0:255],
    output reg [15:0] out[0:255],
    output reg valid
);

reg signed [15:0] zetas[0:127] = '{
    // stage 0 (1 group, stride=128)
    -1044,

    // stage 1 (2 groups, stride=64)
    -758, -359,

    // stage 2 (4 groups, stride=32)
    -1517, 1493, 1422, 287,

    // stage 3 (8 groups, stride=16)
    202, -171, 622, 1577, 182, 962, -1202, -1474,

    // stage 4 (16 groups, stride=8)
    1468, 573, -1325, 264, 383, -829, 1458, -1602,
    -130, -681, 1017, 732, 608, -1542, 411, -205,

    // stage 5 (32 groups, stride=4)
    -1571, 1223, 652, -552, 1015, -1293, 1491, -282,
    -1544, 516, -8, -320, -666, -1618, -1162, 126,
    1469, -853, -90, -271, 830, 107, -1421, -247,
    -951, -398, 961, -1508, -725, 448, -1065, 677,

    // stage 6 (64 groups, stride=2)
    -1275, -1103, 430, 555, 843, -1251, 871, 1550,
    105, 422, 587, 177, -235, -291, -460, 1574,
    1653, -246, 778, 1159, -147, -777, 1483, -602,
    1119, -1590, 644, -872, 349, 418, 329, -156,
    -75, 817, 1097, 603, 610, 1322, -1285, -1465,
    384, -1215, -136, 1218, -1335, -874, 220, -1187,
    -1659, -1185, -1530, -1278, 794, -1510, -854, -870,
    478, -108, -308, 996, 991, 958, -1460, 1522, 1628
};

  wire [15:0] mux_out_a[0:127];
  wire [15:0] mux_out_b[0:127];
  wire signed [11:0] mux_out_zeta[0:127];
  wire [15:0] cooley_out0[0:127];
  wire [15:0] cooley_out1[0:127];

  reg [2:0] stage;
  reg [15:0] buf_in[0:255];
  wire [15:0] a[0:6][0:127];
  wire [15:0] b[0:6][0:127];
  wire signed [15:0] in_mont[0:255];

  poly_tomont mont(.in(in), .out(in_mont));

  // generate a,b for muxes
  genvar s, start, j;
  generate
    for (s = 0; s < 7; s = s + 1) begin : g_stride
      for (start = 0; start < 256; start = start + 2 * (128 >> s)) begin : outer
        for (j = start; j < start + (128 >> s); j = j + 1) begin : inner
          localparam int idx = (start / (2 * (128 >> s))) * (128 >> s) + (j - start);
          assign a[s][idx] = buf_in[j];
          assign b[s][idx] = buf_in[j+(128>>s)];
        end
      end
    end
  endgenerate

  // add them to muxes
  genvar i;
  generate
    for (i = 0; i < 128; i = i + 1) begin
      ntt_mux7 mux_a (
          .in0(a[0][i]),
          .in1(a[1][i]),
          .in2(a[2][i]),
          .in3(a[3][i]),
          .in4(a[4][i]),
          .in5(a[5][i]),
          .in6(a[6][i]),
          .out(mux_out_a[i]),
          .sel(stage)
      );
      ntt_mux7 muxb (
          .in0(b[0][i]),
          .in1(b[1][i]),
          .in2(b[2][i]),
          .in3(b[3][i]),
          .in4(b[4][i]),
          .in5(b[5][i]),
          .in6(b[6][i]),
          .out(mux_out_b[i]),
          .sel(stage)
      );
    end
  endgenerate


  wire signed [11:0] z[0:6][0:127];  // zetas arranged per stage
  // arrange zetas for each stage
  generate
    for (i = 0; i < 128; i++) begin
      assign z[0][i] = zetas[0];  // all use zeta[0]
      assign z[1][i] = zetas[1+(i/64)];  // 2 zetas, each 64x
      assign z[2][i] = zetas[3+(i/32)];  // 4 zetas, each 32x
      assign z[3][i] = zetas[7+(i/16)];  // 8 zetas, each 16x
      assign z[4][i] = zetas[15+(i/8)];  // 16 zetas, each 8x
      assign z[5][i] = zetas[31+(i/4)];  // 32 zetas, each 4x
      assign z[6][i] = zetas[63+(i/2)];  // 64 zetas, each 2x
    end
  endgenerate

  // then mux them
  generate
    for (i = 0; i < 128; i++) begin
      ntt_mux7 mux_z (
          .in0(z[0][i]),
          .in1(z[1][i]),
          .in2(z[2][i]),
          .in3(z[3][i]),
          .in4(z[4][i]),
          .in5(z[5][i]),
          .in6(z[6][i]),
          .out(mux_out_zeta[i]),
          .sel(stage)
      );
    end
  endgenerate
  generate
    for (i = 0; i < 128; i++) begin : g_cooley
      cooley_tookey clt (
          .a(mux_out_a[i]),
          .b(mux_out_b[i]),
          .zeta(mux_out_zeta[i]),
          .out0(cooley_out0[i]),
          .out1(cooley_out1[i])
      );
    end
  endgenerate

  // only for simluation
  initial begin
      stage       = 0;
      busy        = 0;
      write_phase = 0;
      valid       = 0;
  end

  // main ntt behavior
  reg busy;
  integer k;
  reg write_phase;
  integer len;
  integer group;
  integer offset;
  integer base;
  always @(posedge clk) begin
    if (enable && !busy) begin
      for (k = 0; k < 256; k = k + 1)
          buf_in[k] <= in_mont[k];
      stage <= 0;
      valid <= 0;
      write_phase <= 0;
      busy <= 1;
    end else if (busy && !write_phase) begin
      // Phase 0: Let combinational logic settle
      write_phase <= 1;
    end else if (busy && write_phase) begin
    len = 128 >> stage;

    for (k = 0; k < 128; k = k + 1) begin
      group  = k / len;
      offset = k % len;
      base   = group * (len << 1);

      buf_in[base + offset]       <= cooley_out0[k];
      buf_in[base + offset + len] <= cooley_out1[k];
    end

      write_phase <= 0;

      if (stage == 6) begin
        busy  <= 0;
        for (k = 0; k < 256; k = k + 1)
            out[k] <= buf_in[k];
        valid <= 1;
      end else begin
        stage <= stage + 1;
      end
    end else begin
      valid <= 0;
    end
  end
endmodule



module cooley_tookey (
    input  signed [15:0] a,
    input  signed [15:0] b,
    input  signed [11:0] zeta,
    output signed [15:0] out0,
    output signed [15:0] out1
);
  wire signed [15:0] t;
  wire signed [15:0] zeta_ext;

  assign zeta_ext = zeta;

  fqmul mul (
    .a(zeta_ext),
    .b(b),
    .r(t)
  );

  assign out0 = a + t;
  assign out1 = a - t;
endmodule
