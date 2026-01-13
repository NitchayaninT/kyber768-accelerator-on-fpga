module ntt (
    input enable,
    input reset,
    input clk,
    input signed [15:0] in[256],
    output  reg signed[(16*256)-1:0] out,
    output reg valid
);

  reg signed [15:0] zetas[128] = '{
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

  wire signed [15:0] out0[8], out1[8];
  reg signed [15:0] a[8], b[8], zeta[8];
  genvar index;
  generate
    for (index = 0; index < 8; index++) begin : g_cooley
      cooley_tookey clt (
          .clk(clk),
          //input
          .a(a[index]),
          .b(b[index]),
          .zeta(zeta[index]),
          //output
          .out0(out0[index]),
          .out1(out1[index])
      );
    end
  endgenerate

  reg signed [(16 * 256)-1:0] buf_in;
  reg signed [(16 * 256)-1:0] buf_out;

  reg [2:0] stage;  // outer loop

  reg [3:0] cooley_tookey_set;
  reg [7:0] start, len, k, j;
  reg read;  // for read write loop in compute

  reg [2:0] step;  // track which step we are currently doing
  localparam load = 0, compute = 1, next_blk = 2, sync_in_out = 3, next_stage = 4, done = 5, idle = 6;

  integer i;
  always @(posedge clk) begin
    if (reset) begin
      buf_in <= 0;
      buf_out <= 0;
      step <= load;
      stage <= 0;
      cooley_tookey_set <= 0;
      start <= 0;
      j <= 0;
      k <= 1;
      len <= 128;
      read <= 0;
    end else if (enable) begin
      if (step == load) begin
        for (i = 0; i < 256; i++) begin
          buf_in[(i*16)+:16] <= in[i];
        end
        step <= compute;
      end  // save the result from out buffer back to the output
           // raise valid flag
      else if (step == done) begin
        out   <= buf_out;
        valid <= 1;
        step  <= idle;
      end else if (step == sync_in_out) begin
        buf_in <= buf_out;
        step   <= next_stage;
      end  // when finished each stage reset the variable
      else if (step == next_stage) begin
        cooley_tookey_set <= 0;  // each stage use 16 cooley_tookey_set
        len <= len >> 1;
        start <= 0;
        j <= 0;
        if (stage == 6) begin
          step <= done;
        end else begin
          stage <= stage + 1;
          step  <= compute;
        end
      end  // when finish each block update k, start, j
      else if (step == next_blk) begin
        if (stage < 5) begin
          k <= k + 1;
          if (cooley_tookey_set < 15) begin
            start <= j + len;
            j <= j + len;  // c-ref : j = start
            //input
            step <= compute;
          end else begin
            step <= sync_in_out;
          end
        end else if (stage == 5) begin
          k <= k + 2;
          if (cooley_tookey_set < 15) begin
            start <= j + (2 * len);
            j <= j + (2 * len);  // c-ref : j = start
            step <= compute;
          end else begin
            step <= sync_in_out;
          end
        end else if (stage == 6) begin
          k <= k + 4;
          if (cooley_tookey_set < 15) begin
            start <= j + (4 * len);
            j <= j + (4 * len);  // c-ref : j = start
            step <= compute;
          end else begin
            step <= sync_in_out;
          end
        end
      end //end next_blk
      else if (step == compute) begin
        // use this formular for the round that len < 8
        // stage 0 : len = 128;
        // stage 1 : len = 64
        // stage 2 : len = 32
        // stage 3 : len = 16
        // stage 4 : len = 8
        if (stage < 5) begin
          if (!read) begin
            for (i = 0; i < 8; i = i + 1) begin
              a[i] <= buf_in[(j+i)*16+:16];
              b[i] <= buf_in[(j+i+len)*16+:16];
              zeta[i] <= zetas[k];
            end
            read <= 1;
          end else if (read) begin
            for (i = 0; i < 8; i = i + 1) begin
              buf_out[(j+i)*16+:16] <= out0[i];
              buf_out[(j+i+len)*16+:16] <= out1[i];
            end
            if (j + 8 >= start + len) begin
              step <= next_blk;
            end else begin
              j <= j + 8;
              cooley_tookey_set <= cooley_tookey_set + 1;
            end
            read <= 0;
          end
        end

        // stage 5 : len = 4;
        if (stage == 5) begin
          if (!read) begin
            for (i = 0; i < 4; i++) begin
              a[i] <= buf_in[(j+i)*16+:16];
              b[i] <= buf_in[(j+i+len)*16+:16];
              zeta[i] <= zetas[k];
            end
            for (i = 4; i < 8; i++) begin
              // +len since this is another block
              a[i] <= buf_in[(j+i+len)*16+:16];
              b[i] <= buf_in[(j+i+len+len)*16+:16];
              zeta[i] <= zetas[k+1];
            end
          end else if (read) begin
            for (i = 0; i < 4; i++) begin
              buf_out[(j+i)*16+:16] <= out0[i];
              buf_out[(j+i+len)*16+:16] <= out1[i];
            end
            for (i = 4; i < 8; i++) begin
              buf_out[(j+i+len)*16+:16] <= out0[i];
              buf_out[(j+i+len+len)*16+:16] <= out1[i];
            end
            step <= next_blk;
          end
        end
        // stage 6 : len = 2; **last stage**
        if (stage == 6) begin
          if (!read) begin
            for (i = 0; i < 2; i = i + 1) begin
              a[i] <= buf_in[(j+i)*16+:16];
              b[i] <= buf_in[(j+i+len)*16+:16];
              zeta[i] <= zetas[k];
            end
            for (i = 2; i < 4; i = i + 1) begin
              // +len since this is another block
              a[i] <= buf_in[(j+i+len)*16+:16];
              b[i] <= buf_in[(j+i+len+len)*16+:16];
              zeta[i] <= zetas[k+1];
            end
            for (i = 4; i < 6; i = i + 1) begin
              // +len since this is another block
              a[i] <= buf_in[(j+i+(2*len))*16+:16];
              b[i] <= buf_in[(j+i+(3*len))*16+:16];
              zeta[i] <= zetas[k+2];
            end
            for (i = 6; i < 8; i = i + 1) begin
              // +len since this is another block
              a[i] <= buf_in[(j+i+(3*len))*16+:16];
              b[i] <= buf_in[(j+i+(4*len))*16+:16];
              zeta[i] <= zetas[k+3];
            end
          end else if (read) begin
            for (i = 0; i < 2; i++) begin
              buf_out[(j+i)*16+:16] <= out0[i];
              buf_out[(j+i+len)*16+:16] <= out1[i];
            end
            for (i = 2; i < 4; i++) begin
              buf_out[(j+i+len)*16+:16] <= out0[i];
              buf_out[(j+i+(2*len))*16+:16] <= out1[i];
            end
            for (i = 4; i < 6; i++) begin
              buf_out[(j+i+(2*len))*16+:16] <= out0[i];
              buf_out[(j+i+(3*len))*16+:16] <= out1[i];
            end
            for (i = 6; i < 8; i++) begin
              buf_out[(j+i+(3*len))*16+:16] <= out0[i];
              buf_out[(j+i+(4*len))*16+:16] <= out1[i];
            end
            step <= next_blk;
          end
        end
      end
    end  // end for enable
  end  // end always block

  always @(posedge clk) begin
  end
endmodule

module cooley_tookey (
    input clk,
    input signed [15:0] a,
    input signed [15:0] b,
    input signed [15:0] zeta,
    output signed [15:0] out0,
    output signed [15:0] out1
);
  wire signed [15:0] t;

  fqmul mul (
      .clk(clk),
      .a  (zeta),
      .b  (b),
      .r  (t)
  );

  assign out0 = a + t;
  assign out1 = a - t;
endmodule
