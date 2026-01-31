// this design is base on KYBER reference

`include "params.vh"
module poly_basemul_montgomery (
    input clk,
    input start,
    output reg signed [`KYBER_POLY_WIDTH -1 : 0] r[`KYBER_N]
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
  // Declaration of basemul module
  // **************************************************
  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_in_douta[2];
  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_in_doutb[2];
  wire signed [`KYBER_POLY_WIDTH - 1:0] basemul_a[2][2];
  wire signed [`KYBER_POLY_WIDTH - 1:0] basemul_b[2][2];
  wire signed [`KYBER_POLY_WIDTH - 1:0] basemul_r[2][2];
  wire signed [`KYBER_POLY_WIDTH - 1:0] basemul_zeta[2];
  reg basemul_start;
  wire r0_valid;
  wire r1_valid;
  // these 2 variable just for readability
  assign basemul_zeta[0] = zeta_a;
  assign basemul_zeta[1] = zeta_b;
  genvar g;
  generate
    for (g = 0; g < 2; g++) begin : g_basemul
      assign basemul_a[g][0] = ram_in_douta[g][15:0];  // lower half
      assign basemul_a[g][1] = ram_in_douta[g][31:16];  // upper half

      assign basemul_b[g][0] = ram_in_doutb[g][15:0];
      assign basemul_b[g][1] = ram_in_doutb[g][31:16];
      basemul basemul_uut (
          .clk(clk),
          .basemul_start(basemul_start),
          .a(basemul_a[g]),
          .b(basemul_b[g]),
          .zeta(basemul_zeta[g]),
          .r(basemul_r[g]),
          .r0_valid(r0_valid),
          .r1_valid(r1_valid)
      );
    end
  endgenerate

  // **************************************************
  // Implement BRAM for storing input a, b
  // **************************************************
  reg [6:0] ram_in_addra[2];
  reg [6:0] ram_in_addrb[2];
  reg ram_in_we;
  reg ram_in_re;
  generate
    for (g = 0; g < 2; g++) begin : g_rams_input
      rams_dp_nc rams_in (
          .clk  (clk),
          .wea  (ram_in_we),
          .web  (ram_in_we),
          .rea  (ram_in_re),
          .reb  (ram_in_re),
          .addra(ram_in_addra[g]),
          .addrb(ram_in_addrb[g]),
          .dia  (),
          .dib  (),
          .douta(ram_in_douta[g]),
          .doutb(ram_in_doutb[g])
      );
    end
  endgenerate

  // **************************************************
  // Implement BRAM for storing output r
  // **************************************************
  reg [6:0] ram_out_addra;
  reg [6:0] ram_out_addrb;
  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_out_dina;
  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_out_dinb;
  assign ram_out_dina = {basemul_r[0][1], basemul_r[0][1]};
  assign ram_out_dinb = {basemul_r[1][0], basemul_r[1][1]};
  reg ram_out_re;
  reg ram_out_we;
  always @(posedge clk) begin
    if (r0_valid) begin
      ram_out_addra <= ram_in_addra[0];
      ram_out_addrb <= ram_in_addrb[0];
    end else begin
      ram_out_addra <= ram_in_addra[1];
      ram_out_addrb <= ram_in_addrb[1];
    end
  end

  rams_dp_nc rams_output (
      .clk  (clk),
      .wea  (ram_out_we),
      .web  (ram_out_we),
      .rea  (ram_out_re),
      .reb  (ram_out_re),
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
  reg [3:0] basemul_cycle_count;
  reg [5:0] index;  // in 2 basemul design64 times
  reg [2:0] state;

  reg wait_ram_addr;
  // maybe we can write output back at the same times
  always @(posedge clk) begin
    if (start) begin
      // when recieve sstart signal set address and read
      // go to -> wait_ram_addr
      index <= 1;
      wait_ram_addr <= 1;
      rom_zeta_addr <= 64;
      ram_in_re <= 1;
      // first round just set ramaddr manually
      ram_in_addra[0] <= 0;
      ram_in_addrb[0] <= 1;
      ram_in_addra[1] <= 2;
      ram_in_addrb[1] <= 3;
    end else if (wait_ram_addr) begin
      // when changing addr of rams wait 1 cycle
      // then start the next basemul
      basemul_start <= 1;
      wait_ram_addr <= 0;
      basemul_cycle_count <= 0;
    end else if (index < 64) begin
      if (!r0_valid) begin
        basemul_start <= 0;
        basemul_cycle_count <= basemul_cycle_count + 1;
        ram_in_re <= 0;
      end else begin
        ram_out_we <= 1;
        index <= index + 4;
        ram_in_addra[0] <= index * 4;
        ram_in_addrb[0] <= index * 4 + 1;
        ram_in_addra[1] <= index * 4 + 2;
        ram_in_addrb[1] <= index * 4 + 3;
        rom_zeta_addr <= 64 + index;
        ram_in_re <= 1;
        wait_ram_addr <= 1;
      end
    end
  end
endmodule

module d_ff (
    input clk,
    input [6:0] d,
    output reg [6:0] q
);
  always @(posedge clk) begin
    q <= d;
  end
endmodule
