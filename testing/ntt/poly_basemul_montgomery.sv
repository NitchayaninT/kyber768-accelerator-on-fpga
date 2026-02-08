// this design is base on KYBER reference

`include "params.vh"
module poly_basemul_montgomery (
    input clk,
    input start,
    input signed [`KYBER_POLY_WIDTH - 1:0] zeta_a,
    input signed [`KYBER_POLY_WIDTH - 1:0] zeta_b,
    output reg valid
);

  // **************************************************
  // Declaration of basemul module
  // **************************************************
  reg  basemul_start;
  wire basemul0_valid;
  wire basemul1_valid;
  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_in0_dout_low, ram_in1_dout_low;
  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_in0_dout_high, ram_in1_dout_high;
  wire signed [`KYBER_POLY_WIDTH - 1:0] basemul0_a[2], basemul0_b[2];
  wire signed [`KYBER_POLY_WIDTH - 1:0] basemul1_a[2], basemul1_b[2];
  wire signed [`KYBER_POLY_WIDTH - 1:0] basemul0_r[2], basemul1_r[2];
  wire signed [`KYBER_POLY_WIDTH - 1:0] basemul_zeta[2];
  // these 2 variable just for readability
  assign basemul_zeta[0] = zeta_a;  // this is zeta[i]
  assign basemul_zeta[1] = zeta_b;  // this is -zeta[i]
  // get input from 2 ram_in
  // ram_in0 store a
  // ram_in1 store b
  assign basemul0_a[1]   = ram_in0_dout_low[31:16];
  assign basemul0_a[0]   = ram_in0_dout_low[15:0];
  assign basemul0_b[1]   = ram_in1_dout_low[31:16];
  assign basemul0_b[0]   = ram_in1_dout_low[15:0];

  assign basemul1_a[1]   = ram_in0_dout_high[31:16];
  assign basemul1_a[0]   = ram_in0_dout_high[15:0];
  assign basemul1_b[1]   = ram_in1_dout_high[31:16];
  assign basemul1_b[0]   = ram_in1_dout_high[15:0];

  basemul basemul0 (
      .clk(clk),
      .basemul_start(basemul_start),
      .a(basemul0_a),
      .b(basemul0_b),
      .zeta(basemul_zeta[0]),
      .r(basemul0_r),
      .valid(basemul_valid)
  );
  basemul basemul1 (
      .clk(clk),
      .basemul_start(basemul_start),
      .a(basemul1_a),
      .b(basemul1_b),
      .zeta(basemul_zeta[1]),
      .r(basemul1_r),
      .valid(basemul_valid)
  );

  // **************************************************
  // Implement BRAM for storing input a, b
  // **************************************************
  reg [6:0] ram_in0_addr_low, ram_in0_addr_high;
  reg [6:0] ram_in1_addr_low, ram_in1_addr_high;
  reg ram_in_we;
  reg ram_in_en;
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
      .douta(ram_in0_dout_low),
      .doutb(ram_in0_dout_high)
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
      .douta(ram_in1_dout_low),
      .doutb(ram_in1_dout_high)
  );

  // **************************************************
  // Implement BRAM for storing output r
  // **************************************************
  // store basemul0_r
  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_out_dina;
  // store basemul1_r
  wire signed [2*`KYBER_POLY_WIDTH - 1:0] ram_out_dinb;
  assign ram_out_dina = {basemul0_r[1], basemul0_r[0]};
  assign ram_out_dinb = {basemul1_r[1], basemul1_r[0]};
  reg ram_out_en;
  reg ram_out_we;
  reg [6:0] ram_out_addra;  // store input from lower index
  reg [6:0] ram_out_addrb;  // store input from higher index

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
  reg [6:0] index;  // in 2 basemul design64 times

  reg next_index;
  reg wait_ram_in;
  // maybe we can write output back at the same times
  always @(posedge clk) begin
    if (start) begin
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
    end else if (wait_ram_in) begin
      // when changing addr of rams wait 1 cycle
      // then start the next basemul
      basemul_start <= 1;
      wait_ram_in <= 0;
      next_index <= 0;
      ram_out_en <= 0;
      ram_out_we <= 0;
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
    end else begin
      if (!basemul_valid) begin
        ram_out_we <= 0;
        ram_out_en <= 0;
        basemul_start <= 0;
        ram_in_en <= 0;
      end else begin
        ram_out_we <= 1;
        ram_out_en <= 1;
        if (index != 64) next_index <= 1;
        else valid <= 1;
      end
    end
  end
endmodule
