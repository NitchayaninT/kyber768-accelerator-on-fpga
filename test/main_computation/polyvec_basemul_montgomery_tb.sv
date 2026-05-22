import params_pkg::*;

module polyvec_basemul_montgomery_tb;
  logic clk;
  logic enable;
  logic valid;
  logic reset;

  logic ram_we, ram_en;
  logic [6:0] ram_addra, ram_addrb;
  logic [2*KYBER_POLY_WIDTH - 1:0] ram0_dina, ram0_dinb;
  // we never write to this net in this module
  logic [2*KYBER_POLY_WIDTH - 1:0] ram1_dina, ram1_dinb;
  logic [2*KYBER_POLY_WIDTH - 1:0] ram0_douta[3], ram0_doutb[3];
  logic [2*KYBER_POLY_WIDTH - 1:0] ram1_douta[3], ram1_doutb[3];

  genvar i;
  generate
    for (i = 0; i < 3; i++) begin : g_bram

      // try store t_vec
      rams_dp #() ram_tvec (
          .clk  (clk),
          .wea  (ram_we),
          .web  (ram_we),
          .ena  (ram_en),
          .enb  (ram_en),
          .addra(ram_addra),
          .addrb(ram_addrb),
          .dina (ram0_dina),
          .dinb (ram0_dinb),
          .douta(ram0_douta[i]),
          .doutb(ram0_doutb[i])
      );

      // try store r
      rams_dp #() ram_r (
          .clk  (clk),
          .wea  (),
          .web  (),
          .ena  (ram_en),
          .enb  (ram_en),
          .addra(ram_addra),
          .addrb(ram_addrb),
          .dina (ram1_dina),
          .dinb (ram1_dinb),
          .douta(ram1_douta[i]),
          .doutb(ram1_doutb[i])
      );
    end
  endgenerate

  // NOTE zeta b is never used in polyvec_basemul_montgomery
  logic [MC_RAM_ADDR_BITS - 1:0] rom_zeta_addra, rom_zeta_addrb;
  logic signed [KYBER_POLY_WIDTH - 1:0] zeta_a, zeta_b;
  rom_zetas rom_zetas (
      .clk  (clk),
      .addra(rom_zeta_addra),
      .addrb(rom_zeta_addrb),
      .douta(zeta_a),
      .doutb(zeta_b)
  );

  polyvec_basemul_montgomery polyvec_basemul_montgomery (
      .clk             (clk),
      .reset           (reset),
      .enable          (enable),
      .valid           (valid),
      .zeta            (zeta_a),
      .rom_zeta_addr   (rom_zeta_addra),
      .ram0_read_data_a(ram0_douta),
      .ram0_read_data_b(ram0_doutb),
      .ram1_read_data_a(ram1_douta),
      .ram1_read_data_b(ram1_doutb),
      .ram_write_data_a(ram0_dina),
      .ram_write_data_b(ram0_dinb),
      .ram_we          (ram_we),
      .ram_en          (ram_en),
      .ram_addra       (ram_addra),
      .ram_addrb       (ram_addrb)
  );

  initial begin
    forever begin
      #1 clk <= ~clk;
    end
  end

  int index;
  integer fd;
  initial begin
    enable <= 0;
    reset  <= 1;
    fd = $fopen("/home/pakin/kyber/data/test_result/polyvec_basemul.hex", "w");
    if (fd == 0) $fatal("Cant open files");
    $readmemh("tvec0_32bits.mem", g_bram[0].ram_tvec.RAM);
    $readmemh("tvec1_32bits.mem", g_bram[1].ram_tvec.RAM);
    $readmemh("tvec2_32bits.mem", g_bram[2].ram_tvec.RAM);
    $readmemh("r0_32bits.mem", g_bram[0].ram_r.RAM);
    $readmemh("r1_32bits.mem", g_bram[1].ram_r.RAM);
    $readmemh("r2_32bits.mem", g_bram[2].ram_r.RAM);
    clk <= 1;
    #2 reset <= 0;
    #10;
    enable <= 1;
    #4;
    enable <= 0;
    wait (valid);
    #10
    for (index = 0; index < 128; index++) begin
      $display("index%d : %0d", (index * 2), g_bram[0].ram_tvec.RAM[index][15:0]);
      $fdisplay(fd, "%h", g_bram[0].ram_tvec.RAM[index][15:0]);
      $display("index%d : %0d", (index * 2 + 1), g_bram[0].ram_tvec.RAM[index][31:16]);
      $fdisplay(fd, "%h", g_bram[0].ram_tvec.RAM[index][31:16]);
    end
    $fclose(fd);
    $finish;
  end
endmodule
