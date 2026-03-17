import params_pkg::*;
import enums_pkg::*;

module ntt_tb;
  logic clk, reset, enable;
  ntt_mode_e mode;
  logic valid;

  wire signed [KYBER_POLY_WIDTH - 1:0] zeta_a;
  wire signed [KYBER_POLY_WIDTH - 1:0] zeta_b;
  reg [6:0] rom_zeta_addra;
  reg [6:0] rom_zeta_addrb;
  rom_zetas #() rom_zetas (
      .clk  (clk),
      .addra(rom_zeta_addra),
      .addrb(rom_zeta_addrb),
      .douta(zeta_a),
      .doutb(zeta_b)
  );

  logic signed [KYBER_POLY_WIDTH - 1:0] zeta_inv_a;
  logic signed [KYBER_POLY_WIDTH - 1:0] zeta_inv_b;
  wire [6:0] rom_zeta_inv_addra;
  wire [6:0] rom_zeta_inv_addrb;
  rom_zetas_inv rom_zetas_inv (
      .clk  (clk),
      .addra(rom_zeta_inv_addra),
      .addrb(rom_zeta_inv_addrb),
      .douta(zeta_inv_a),
      .doutb(zeta_inv_b)
  );

  wire [6:0] ram_in_addra;
  wire [6:0] ram_in_addrb;
  logic ram_in_we, ram_in_en;
  logic [2*KYBER_POLY_WIDTH - 1 : 0] ram_in_dina;
  logic [2*KYBER_POLY_WIDTH - 1 : 0] ram_in_dinb;
  logic [2*KYBER_POLY_WIDTH - 1 : 0] ram_in_douta;
  logic [2*KYBER_POLY_WIDTH - 1 : 0] ram_in_doutb;


  rams_dp #() rams_dp (
      .clk  (clk),
      .wea  (ram_in_we),
      .web  (ram_in_we),
      .ena  (ram_in_en),
      .enb  (ram_in_en),
      .addra(ram_in_addra),
      .addrb(ram_in_addrb),
      .dina (ram_in_dina),
      .dinb (ram_in_dinb),
      .douta(ram_in_douta),
      .doutb(ram_in_doutb)
  );

  ntt #() ntt (
      .clk               (clk),
      .reset             (reset),
      .enable            (enable),
      .mode              (mode),
      .valid             (valid),
      .ram_read_data_a   (ram_in_douta),
      .ram_read_data_b   (ram_in_doutb),
      .ram_write_data_a  (ram_in_dina),
      .ram_write_data_b  (ram_in_dinb),
      .ram_addra         (ram_in_addra),
      .ram_addrb         (ram_in_addrb),
      .ram_en            (ram_in_en),
      .ram_we            (ram_in_we),
      .zeta_a            (zeta_a),
      .zeta_b            (zeta_b),
      .rom_zeta_addra    (rom_zeta_addra),
      .rom_zeta_addrb    (rom_zeta_addrb),
      .zeta_inv_a        (zeta_inv_a),
      .zeta_inv_b        (zeta_inv_b),
      .rom_zeta_inv_addra(rom_zeta_inv_addra),
      .rom_zeta_inv_addrb(rom_zeta_inv_addrb)
  );

  int fd;
  int i;
  always #1 clk = ~clk;
  initial begin
    //$readmemh("ntt.mem", rams_dp.RAM);
    $readmemh("r1_32bits.mem", rams_dp.RAM);
    mode <= NTT;
    clk <= 0;
    enable <= 0;
    reset <= 1;

    #10 enable <= 1;
    reset <= 0;
    #2 enable <= 0;
    wait (valid == 1) begin
      fd = $fopen("/home/pakin/kyber/data/test_result/ntt.hex", "w");
      for (i = 0; i < 128; i++) begin
        // lower index first
        $display("index%d : %0d", (i * 2), rams_dp.RAM[i][15:0]);
        $fdisplay(fd, "%h", rams_dp.RAM[i][15:0]);
        $display("index%d : %0d", (i * 2 + 1), rams_dp.RAM[i][31:16]);
        $fdisplay(fd, "%h", rams_dp.RAM[i][31:16]);
      end
      $fclose(fd);
    end
    #200 mode <= INV_NTT;
    $readmemh("pvbm_at0_32bits.hex", rams_dp.RAM);
    #2 enable <= 1;
    #2 enable <= 0;

    wait (valid == 1) begin
      fd = $fopen("/home/pakin/kyber/data/test_result/inv_ntt.hex", "w");
      for (i = 0; i < 128; i++) begin
        // lower index first
        $display("index%d : %0d", (i * 2), rams_dp.RAM[i][15:0]);
        $fdisplay(fd, "%h", rams_dp.RAM[i][15:0]);
        $display("index%d : %0d", (i * 2 + 1), rams_dp.RAM[i][31:16]);
        $fdisplay(fd, "%h", rams_dp.RAM[i][31:16]);
      end
      $fclose(fd);
    end
    #20 $finish;
  end

endmodule

