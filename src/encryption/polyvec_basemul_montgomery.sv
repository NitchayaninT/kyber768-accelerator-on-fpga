`include "params.vh"
module polyvec_basemul_montgomery (
    input clk,
    input rst,
    input start,
    output reg valid
);

  // **************************************************
  // Implement ROM with BRAM for storing zetas
  // **************************************************

  wire signed [`KYBER_POLY_WIDTH - 1:0] zeta_a;
  wire signed [`KYBER_POLY_WIDTH - 1:0] zeta_b;
  reg [6:0] rom_zeta_addr;
  rom_zetas rom_zetas (
      .clk (clk),
      .addr(rom_zeta_addr),
      .dout(zeta_a)
  );
  assign zeta_b = -zeta_a;

  // **************************************************
  // Implement 3 BRAMS for storing input a, b
  // **************************************************
  reg [6:0] ram_in0_addr_low, ram_in0_addr_high;
  reg [6:0] ram_in1_addr_low, ram_in1_addr_high;
  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_in0_dout_low[3], ram_in1_dout_low[3];
  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_in0_dout_high[3], ram_in1_dout_high[3];
  reg ram_in_we;
  reg ram_in_en;

  genvar g;
  generate
    for (g = 0; g < 3; g++) begin : g_ram_in
      rams_dp_nc ram_in0 (
          .clk  (clk),
          .wea  (ram_in_we),
          .web  (ram_in_we),
          .ena  (ram_in_en),
          .enb  (ram_in_en),
          .addra(ram_in0_addr_low),
          .addrb(ram_in0_addr_high),
          .dia  (),
          .dib  (),
          .douta(ram_in0_dout_low[g]),
          .doutb(ram_in0_dout_high[g])
      );
      rams_dp_nc ram_in1 (
          .clk  (clk),
          .wea  (ram_in_we),
          .web  (ram_in_we),
          .ena  (ram_in_en),
          .enb  (ram_in_en),
          .addra(ram_in1_addr_low),
          .addrb(ram_in1_addr_high),
          .dia  (),
          .dib  (),
          .douta(ram_in1_dout_low[g]),
          .doutb(ram_in1_dout_high[g])
      );
    end
  endgenerate

  // **************************************************
  // Barett reductions modules
  // **************************************************
  // get output from the poly_basemul_mongomery
  // add them together, then apply barret reduction
  wire signed [`KYBER_POLY_WIDTH - 1 : 0] basemul0_r[3][2], basemul1_r[3][2];
  wire signed [`KYBER_POLY_WIDTH -1:0] sum_basemul0_r[2];
  wire signed [`KYBER_POLY_WIDTH -1:0] sum_basemul1_r[2];
  assign sum_basemul0_r[1] = basemul0_r[0][1] + basemul0_r[1][1] + basemul0_r[2][1]; //sum_basemul0_rh
  assign sum_basemul0_r[0] = basemul0_r[0][0] + basemul0_r[1][0] + basemul0_r[2][0]; //sum_basemul0_rl
  assign sum_basemul1_r[1] = basemul1_r[0][1] + basemul1_r[1][1] + basemul1_r[2][1]; //sum_basemul1_rh
  assign sum_basemul1_r[0] = basemul1_r[0][0] + basemul1_r[1][0] + basemul1_r[2][0]; //sum_basemul1_rl

  wire [`KYBER_POLY_WIDTH - 1 : 0] barrett_r0[2];
  wire [`KYBER_POLY_WIDTH - 1 : 0] barrett_r1[2];
  reg barrett_start;
  generate
    for (g = 0; g < 2; g++) begin
      barrett_reduce barrett_red_sum_b0 (
          .clk  (clk),
          .start(barrett_start),
          .a    (sum_basemul0_r[g]),
          .r    (barrett_r0[g])
      );
      barrett_reduce barrett_red_sum_b1 (
          .clk  (clk),
          .start(barrett_start),
          .a    (sum_basemul1_r[g]),
          .r    (barrett_r1[g])
      );
    end
  endgenerate

  // **************************************************
  // Implement BRAM for storing output r
  // **************************************************
  reg ram_out_en;
  reg ram_out_we;
  reg [6:0] ram_out_addra;  // store input from lower index
  reg [6:0] ram_out_addrb;  // store input from higher index

  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_out_dina;  // store basemul r0
  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_out_dinb;  // store basemul r1

  assign ram_out_dina = {barrett_r0[1], barrett_r0[0]};
  assign ram_out_dinb = {barrett_r1[1], barrett_r1[0]};
  rams_dp_nc ram_output (
      .clk  (clk),
      .wea  (ram_out_we),
      .web  (ram_out_we),
      .ena  (ram_out_en),
      .enb  (ram_out_en),
      .addra(ram_out_addra),
      .addrb(ram_out_addrb),
      .dia  (ram_out_dina),
      .dib  (ram_out_dinb),
      .douta(),
      .doutb()
  );

  // **************************************************
  // control signal & Main behavior
  // **************************************************

  wire basemul_valid[3];
  wire all_valid = basemul_valid[0] && basemul_valid[1] && basemul_valid[2];
  reg basemul_start;
  generate
    for (g = 0; g < 3; g++) begin : g_poly_basemul_montgomery
      poly_basemul_montgomery pbm (
          .clk(clk),
          .start(basemul_start),
          .ram_in0_dout_low(ram_in0_dout_low[g]),
          .ram_in1_dout_low(ram_in1_dout_low[g]),
          .ram_in0_dout_high(ram_in0_dout_high[g]),
          .ram_in1_dout_high(ram_in1_dout_high[g]),
          .zeta_a(zeta_a),
          .zeta_b(zeta_b),
          .basemul0_r(basemul0_r[g]),
          .basemul1_r(basemul1_r[g]),
          .valid(basemul_valid[g])
      );
    end
  endgenerate
  reg [6:0] index;  // in 2 basemul design64 times

  reg [1:0] barrett_count;
  reg barrett_enable;
  reg next_index;
  reg wait_ram_in;
  // maybe we can write output back at the same times
  //localparam LOAD = 0, MUL = 1, ADD = 2;
  always @(posedge clk) begin
    if (rst) begin
      barrett_enable <= 0;
      barrett_start  <= 0;
      barrett_count  <= 0;
      wait_ram_in    <= 0;
      next_index     <= 0;
      basemul_start  <= 0;
      ram_in_en      <= 0;
      ram_out_en     <= 0;
      ram_out_we     <= 0;
      valid          <= 0;
      index          <= 0;
    end else if (start) begin
      // when recieve sstart signal set address and read
      // go to -> wait_ram_addr
      index <= 1;
      wait_ram_in <= 1;
      rom_zeta_addr <= 64;
      ram_in_en <= 1;
      ram_out_en <= 0;
      ram_out_we <= 0;
      next_index <= 0;
      valid <= 0;
      // first round just set ramaddr manually
      ram_out_addra <= 0;
      ram_out_addrb <= 1;
      ram_in0_addr_low <= 0;
      ram_in0_addr_high <= 1;
      ram_in1_addr_low <= 0;
      ram_in1_addr_high <= 1;
      // barrett
      barrett_start <= 0;
      barrett_enable <= 0;
      barrett_count <= 0;
    end else if (wait_ram_in) begin
      // when changing addr of rams wait 1 cycle
      // then start the next basemul
      basemul_start <= 1;
      wait_ram_in <= 0;
      next_index <= 0;
    end else if (next_index) begin
      index <= index + 1;
      ram_out_addra <= index * 2;
      ram_out_addrb <= index * 2 + 1;
      ram_in0_addr_low <= index * 2;
      ram_in0_addr_high <= index * 2 + 1;
      ram_in1_addr_low <= index * 2;
      ram_in1_addr_high <= index * 2 + 1;
      rom_zeta_addr <= rom_zeta_addr + 1;
      ram_in_en <= 1;
      wait_ram_in <= 1;
      ram_out_en <= 0;
      ram_out_we <= 0;
    end else if (barrett_enable) begin
      if (barrett_start) begin
        barrett_start <= 0;
        barrett_count <= 0;
      end else begin
        if (barrett_count == 2) begin
          ram_out_we <= 1;
          ram_out_en <= 1;
          barrett_enable <= 0;
          barrett_count <= 0;
          if (index != 64) next_index <= 1;
          else if (index == 64) valid <= 1;
        end else barrett_count <= barrett_count + 1;
      end
    end else begin
      // potential issues is here depents on all valid at the same time
      if (!all_valid) begin
        ram_out_we <= 0;
        ram_out_en <= 0;
        basemul_start <= 0;
        ram_in_en <= 0;
      end else if (all_valid == 1) begin
        barrett_enable <= 1;
        barrett_start  <= 1;
      end
    end
  end
endmodule
