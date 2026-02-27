// ******************************************************
// Main computation module is a top modules for
// 1. NTT
// 2. Polyvec_basemul_montgomery
// 3. INVNTT
// This module contain multiple BRAM that can be use and shared by these
// three modules and also include loading data from external module
// ******************************************************
import params_pkg::*;
import enums_pkg::*;

typedef enum logic [1:0] {
  MC_LR_IDLE,
  MC_LR_START,
  MC_LR_LOAD,
  MC_LR_DONE
} mc_lr_state_e;

typedef enum logic [2:0] {
  MC_NTT_IDLE,
  MC_NTT_0,
  MC_NTT_1,
  MC_NTT_2,
  MC_NTT_DONE
} mc_ntt_round_e;

typedef enum logic [2:0] {
  MC_PVBM_IDLE,
  MC_PVBM_AT0,
  MC_PVBM_AT1,
  MC_PVBM_AT2,
  MC_PVBM_TVEC,
  MC_PVBM_DONE
} mc_pvbm_state_e;

// 3 input polyvec
// 1. a_t   -> BRAM 0-8
// 2. t_vec -> BRAM 9-11
// 3. r     -> BRAM 12-14
module main_computation (
    input clk,
    input enable,
    input reset,
    input main_compute_mode_e mode,  // 0 = enc, 1 = dec
    input [KYBER_POLY_WIDTH-1 : 0] a_t[0:(KYBER_K*KYBER_K)-1][0:KYBER_N-1],
    input [KYBER_POLY_WIDTH-1:0] r[0:KYBER_K-1][0:KYBER_N-1],
    input [(KYBER_N * KYBER_RQ_WIDTH)-1:0] t_vec[3],
    output logic valid
);

  main_compute_state_e current_state, next_state;
  mc_ntt_round_e ntt_current_state, ntt_next_state;
  mc_pvbm_state_e pvbm_current_state, pvbm_next_state;

  wire [KYBER_POLY_WIDTH - 1 : 0] t_vec_transform[3][256];

  genvar i, j;
  generate
    for (j = 0; j < 3; j++) begin : g_t_vec
      for (i = 0; i < 256; i++) begin : g_t_vec_coeffs
        assign t_vec_transform[j][i] = {4'd0, t_vec[j][KYBER_RQ_WIDTH*i+:KYBER_RQ_WIDTH]};
      end
    end
  endgenerate

  // **************************************************
  // Implement BRAM for storing input polynomial vectors
  // **************************************************
  // IMPORTANT! ram_addra, ram_addrb, ram_we, ram_en
  // are driven by NTT, INVNTT or POLYVEC_BASEMUL_MONTGOMERY
  // need to create seperate wire for each step and assign in always_comb
  logic [6:0] ram_addra;
  logic [6:0] ram_addrb;
  logic [2*KYBER_POLY_WIDTH - 1 : 0] ram_dina[15];
  logic [2*KYBER_POLY_WIDTH - 1 : 0] ram_dinb[15];
  logic [2*KYBER_POLY_WIDTH - 1 : 0] ram_douta[15];
  logic [2*KYBER_POLY_WIDTH - 1 : 0] ram_doutb[15];
  logic ram_we[15], ram_en[15];

  // douta, doutb don't need other variance since it is output wire that are
  // read by other module

  logic [6:0] lr_ram_addra;
  logic [6:0] lr_ram_addrb;
  logic [2*KYBER_POLY_WIDTH - 1 : 0] lr_ram_dina[15];
  logic [2*KYBER_POLY_WIDTH - 1 : 0] lr_ram_dinb[15];
  logic lr_ram_we, lr_ram_en;

  logic [6:0] ntt_ram_addra;
  logic [6:0] ntt_ram_addrb;
  logic [2*KYBER_POLY_WIDTH - 1 : 0] ntt_ram_dina;
  logic [2*KYBER_POLY_WIDTH - 1 : 0] ntt_ram_dinb;
  logic ntt_ram_we[3], ntt_ram_en[3];

  logic [6:0] pvbm_ram_addra;
  logic [6:0] pvbm_ram_addrb;
  logic [2*KYBER_POLY_WIDTH - 1 : 0] pvbm_ram_dina; // dina will save from a_t[0], a_t[3], a_t[6], t_vec[0]
  logic [2*KYBER_POLY_WIDTH - 1 : 0] pvbm_ram_dinb; // dinb will save from a_t[0], a_t[3], a_t[6], t_vec[0]
  logic pvbm_ram_we[4], pvbm_ram_en[15];

  generate
    assign ram_addra = (current_state == MC_LOAD_RAM) ? lr_ram_addra : (current_state == MC_NTT)? ntt_ram_addra:(current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_addra :0;
    assign ram_addrb = (current_state == MC_LOAD_RAM) ? lr_ram_addrb : (current_state == MC_NTT)? ntt_ram_addrb:(current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_addrb :0;

    for (i = 0; i < 9; i++) begin : g_at_ram
      if (i % 3 == 0) begin : g_at_ram_writeback
        assign ram_we[i]   = (current_state == MC_LOAD_RAM) ? lr_ram_we      : (current_state == MC_NTT)? 0: (current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_we[i/3]:0;
        assign ram_en[i]   = (current_state == MC_LOAD_RAM) ? lr_ram_en      : (current_state == MC_NTT)? 0 : (current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_en[i]:0;
        assign ram_dina[i] = (current_state == MC_LOAD_RAM) ? lr_ram_dina[i] : (current_state == MC_NTT)? 0: (current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_dina:0;
        assign ram_dinb[i] = (current_state == MC_LOAD_RAM) ? lr_ram_dinb[i] : (current_state == MC_NTT)? 0: (current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_dinb:0;

      end else begin : g_at_ram_normal
        assign ram_we[i]   = (current_state == MC_LOAD_RAM) ? lr_ram_we      : (current_state == MC_NTT)? 0:0;
        assign ram_en[i]   = (current_state == MC_LOAD_RAM) ? lr_ram_en      : (current_state == MC_NTT)? 0 : (current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_en[i]:0;
        assign ram_dina[i] = (current_state == MC_LOAD_RAM) ? lr_ram_dina[i] : (current_state == MC_NTT)? 0:0;
        assign ram_dinb[i] = (current_state == MC_LOAD_RAM) ? lr_ram_dinb[i] : (current_state == MC_NTT)? 0:0;
      end
    end

    // ram signal for tvec
    for (i = 9; i < 12; i++) begin : g_tvec_ram

      if (i == 9) begin : g_tvec_ram_writeback
        assign ram_we[i]   = (current_state == MC_LOAD_RAM) ? lr_ram_we      : (current_state == MC_NTT)? 0: (current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_we[i/3]:0;
        assign ram_en[i]   = (current_state == MC_LOAD_RAM) ? lr_ram_en      : (current_state == MC_NTT)? 0: (current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_en[i]:0;
        assign ram_dina[i] = (current_state == MC_LOAD_RAM) ? lr_ram_dina[i] : (current_state == MC_NTT)? 0: (current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_dina :0;
        assign ram_dinb[i] = (current_state == MC_LOAD_RAM) ? lr_ram_dinb[i] : (current_state == MC_NTT)? 0: (current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_dinb :0;

      end else begin : g_tvec_ram_normal
        assign ram_we[i]   = (current_state == MC_LOAD_RAM) ? lr_ram_we      : (current_state == MC_NTT)? 0:0;
        assign ram_en[i]   = (current_state == MC_LOAD_RAM) ? lr_ram_en      : (current_state == MC_NTT)? 0:(current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_en[i]:0;
        assign ram_dina[i] = (current_state == MC_LOAD_RAM) ? lr_ram_dina[i] : (current_state == MC_NTT)? 0:0;
        assign ram_dinb[i] = (current_state == MC_LOAD_RAM) ? lr_ram_dinb[i] : (current_state == MC_NTT)? 0:0;
      end
    end

    // ram r does not need write back since it never write back
    for (i = 12; i < 15; i++) begin : g_r_ram
      assign ram_we[i]   = (current_state == MC_LOAD_RAM) ? lr_ram_we      : (current_state == MC_NTT)? ntt_ram_we[i-12]:0;
      assign ram_en[i]   = (current_state == MC_LOAD_RAM) ? lr_ram_en      : (current_state == MC_NTT)? ntt_ram_en[i-12]: (current_state == MC_POLYVEC_BASEMUL)? pvbm_ram_en[i]:0;
      assign ram_dina[i] = (current_state == MC_LOAD_RAM) ? lr_ram_dina[i] : (current_state == MC_NTT)? ntt_ram_dina:0;
      assign ram_dinb[i] = (current_state == MC_LOAD_RAM) ? lr_ram_dinb[i] : (current_state == MC_NTT)? ntt_ram_dinb:0;
    end
  endgenerate

  for (i = 0; i < 15; i++) begin : g_bram
    rams_dp #() rams_dp (
        .clk  (clk),
        .wea  (ram_we[i]),
        .web  (ram_we[i]),
        .ena  (ram_en[i]),
        .enb  (ram_en[i]),
        .addra(ram_addra),
        .addrb(ram_addrb),
        .dina (ram_dina[i]),
        .dinb (ram_dinb[i]),
        .douta(ram_douta[i]),
        .doutb(ram_doutb[i])
    );
  end

  // **************************************************
  // Implement ROM with BRAM for storing zetas
  // **************************************************
  // IMPORTANT! rom_zeta_addra, and rom_zeta_addrb
  // are driven by NTT, INVNTT or POLYVEC_BASEMUL_MONTGOMERY
  // need to create seperate wire for each step and assign in always_comb

  wire signed [KYBER_POLY_WIDTH - 1:0] zeta_a;
  wire signed [KYBER_POLY_WIDTH - 1:0] zeta_b;
  reg [6:0] rom_zeta_addra;
  reg [6:0] rom_zeta_addrb;

  reg [6:0] ntt_rom_zeta_addra;
  reg [6:0] ntt_rom_zeta_addrb;

  reg [6:0] pvbm_rom_zeta_addra;

  assign rom_zeta_addra = (current_state == MC_NTT)? ntt_rom_zeta_addra: (current_state == MC_POLYVEC_BASEMUL)? pvbm_rom_zeta_addra:0;
  assign rom_zeta_addrb = (current_state == MC_NTT) ? ntt_rom_zeta_addrb : 0;

  rom_zetas #() rom_zetas (
      .clk  (clk),
      .addra(rom_zeta_addra),
      .addrb(rom_zeta_addrb),
      .douta(zeta_a),
      .doutb(zeta_b)
  );

  // **************************************************
  // Implement ROM with BRAM for storing zetas
  // **************************************************
  logic signed [KYBER_POLY_WIDTH - 1 : 0] zeta_inv_a;
  logic signed [KYBER_POLY_WIDTH - 1 : 0] zeta_inv_b;
  logic [MC_ZETA_ADDR_BITS - 1:0] zeta_inv_addra;
  logic [MC_ZETA_ADDR_BITS - 1:0] zeta_inv_addrb;

  // **************************************************
  // NTT module convert noise r into ntt form
  // **************************************************
  ntt_mode_e ntt_mode;
  assign ntt_mode = (current_state == MC_INV_NTT) ? INV_NTT : NTT;

  logic [2 * KYBER_POLY_WIDTH - 1:0] ntt_ram_read_data_a;
  logic [2 * KYBER_POLY_WIDTH - 1:0] ntt_ram_read_data_b;
  assign ntt_ram_read_data_a = (ntt_current_state == MC_NTT_0)? ram_douta[12]: (ntt_current_state == MC_NTT_1)? ram_douta[13] : ram_douta[14];
  assign ntt_ram_read_data_b = (ntt_current_state == MC_NTT_0)? ram_doutb[12]: (ntt_current_state == MC_NTT_1)? ram_doutb[13] : ram_doutb[14];

  // output from ntt module waiting to wring back to RAMS
  // just set for all 3 poly r but choose wrtiing with enable signal
  logic [2 * KYBER_POLY_WIDTH - 1:0] ntt_ram_write_data_a;
  logic [2 * KYBER_POLY_WIDTH - 1:0] ntt_ram_write_data_b;
  assign ntt_ram_dina = ntt_ram_write_data_a;
  assign ntt_ram_dinb = ntt_ram_write_data_b;

  logic ntt_valid;  // ntt_valid will be raised when each poly is finished
  logic ntt_done;  // ntt_done will be raised when all 3 polynomials are finished
  logic ntt_start;  // ntt start indicate transition of FSM from LOAD_RAM to NTT
  logic ntt_enable;
  logic ntt_enable_delay;
  always_ff @(posedge clk) ntt_enable_delay <= ntt_enable;

  //assign ntt_done = (ntt_valid & ntt_current_state == MC_NTT_2) ;

  // The enable port that connect to the ntt module
  // NOTE: this 2 ports does not connect to RAMS directly ,since NTT should be
  // done one poly at a time and we don't want to enable all ram_we
  // there are ntt_ram_en[3] and ntt_ram_we[3] that connect to RAMS
  logic ntt_ram_en_predec, ntt_ram_we_predec;

  wor ntt_enable_or = ntt_enable | ntt_enable_delay; // this is a quick fix for enable timing don't last long enough
  // TODO choosing to write only in their ntt_rounds
  ntt nnt_dut (
      .clk               (clk),
      .reset             (reset),
      .enable            (ntt_enable_or),
      .mode              (ntt_mode),
      .valid             (ntt_valid),
      .ram_read_data_a   (ntt_ram_read_data_a),
      .ram_read_data_b   (ntt_ram_read_data_b),
      .ram_write_data_a  (ntt_ram_write_data_a),
      .ram_write_data_b  (ntt_ram_write_data_b),
      .ram_addra         (ntt_ram_addra),
      .ram_addrb         (ntt_ram_addrb),
      .ram_en            (ntt_ram_en_predec),
      .ram_we            (ntt_ram_we_predec),
      .zeta_a            (zeta_a),
      .zeta_b            (zeta_b),
      .rom_zeta_addra    (ntt_rom_zeta_addra),
      .rom_zeta_addrb    (ntt_rom_zeta_addrb),
      .zeta_inv_a        (zeta_inv_a),
      .zeta_inv_b        (zeta_inv_b),
      .rom_zeta_inv_addra(zeta_inv_addra),
      .rom_zeta_inv_addrb(zeta_inv_addrb)
  );

  // **************************************************
  // polyvec_basemul_montgomery module
  // **************************************************

  logic pvbm_enable;  // NOTE: the enable are signal pass to the module to start
  logic pvbm_enable_delay;
  always_ff @(posedge clk)
    pvbm_enable_delay <= pvbm_enable;  // could be optimized?, maybe change enable to ff?
  //or pvbm_enable_or = pvbm_enable || pvbm_enable_delay;

  logic pvbm_start, pvbm_valid;
  logic [2* KYBER_POLY_WIDTH -1 : 0] pvbm_ram0_read_data_a [3];
  logic [2* KYBER_POLY_WIDTH -1 : 0] pvbm_ram0_read_data_b [3];
  logic [2* KYBER_POLY_WIDTH -1 : 0] pvbm_ram1_read_data_a [3];
  logic [2* KYBER_POLY_WIDTH -1 : 0] pvbm_ram1_read_data_b [3];
  logic [2* KYBER_POLY_WIDTH -1 : 0] pvbm_ram_write_data_a;
  logic [2* KYBER_POLY_WIDTH -1 : 0] pvbm_ram_write_data_b;

  generate
    for (i = 0; i < 3; i++) begin : g_pvbm_signal
      // connect the first operand base on pvbm_current_state
      assign pvbm_ram0_read_data_a[i] = (pvbm_current_state == MC_PVBM_AT0)? ram_douta[i]: (pvbm_current_state == MC_PVBM_AT1)? ram_douta[i+3]: (pvbm_current_state == MC_PVBM_AT2)? ram_douta[i+6]: (
      pvbm_current_state == MC_PVBM_TVEC)? ram_douta[i+9]:0;
      assign pvbm_ram0_read_data_b[i] = (pvbm_current_state == MC_PVBM_AT0)? ram_doutb[i]: (pvbm_current_state == MC_PVBM_AT1)? ram_doutb[i+3]: (pvbm_current_state == MC_PVBM_AT2)? ram_doutb[i+6]: (
      pvbm_current_state == MC_PVBM_TVEC)? ram_doutb[i+9]:0;

      // always connect ram1 to r (second operand) : since everything multiply by r
      assign pvbm_ram1_read_data_a[i] = ram_douta[i+12];
      assign pvbm_ram1_read_data_b[i] = ram_doutb[i+12];
    end
  endgenerate

  assign pvbm_ram_dina = pvbm_ram_write_data_a;
  assign pvbm_ram_dinb = pvbm_ram_write_data_b;
  logic pvbm_ram_we_predec, pvbm_ram_en_predec;
  polyvec_basemul_montgomery polyvec_basemul_montgomery (
      .clk             (clk),
      .reset           (reset),
      .enable          (pvbm_enable_delay),
      .valid           (pvbm_valid),
      .zeta            (zeta_a),
      .rom_zeta_addr   (pvbm_rom_zeta_addra),
      .ram0_read_data_a(pvbm_ram0_read_data_a),
      .ram0_read_data_b(pvbm_ram0_read_data_b),
      .ram1_read_data_a(pvbm_ram1_read_data_a),
      .ram1_read_data_b(pvbm_ram1_read_data_b),
      .ram_write_data_a(pvbm_ram_write_data_a),
      .ram_write_data_b(pvbm_ram_write_data_b),
      .ram_we          (pvbm_ram_we_predec),
      .ram_en          (pvbm_ram_en_predec),
      .ram_addra       (pvbm_ram_addra),
      .ram_addrb       (pvbm_ram_addrb)
  );

  // **************************************************
  // Define main behavior
  // **************************************************

  logic pvbm_done, inv_ntt_done;
  logic lr_start, lr_done;
  // Try two always block methods

  // Combinational block for Main Computations
  always_comb begin
    // Default state
    next_state = MC_IDLE;
    // default vaule
    valid = 0;
    lr_start = 0;
    ntt_start = 0;
    pvbm_start = 0;

    case (current_state)
      MC_IDLE: begin
        if (enable) begin
          next_state = MC_LOAD_RAM;
          lr_start   = 1;
        end
      end

      MC_LOAD_RAM: begin
        if (lr_done) begin
          ntt_start  = 1;
          next_state = MC_NTT;
        end else next_state = MC_LOAD_RAM;
      end

      MC_NTT: begin
        if (ntt_done) begin
          next_state = MC_POLYVEC_BASEMUL;
          pvbm_start = 1;
        end else next_state = MC_NTT;
      end

      MC_POLYVEC_BASEMUL: begin
        if (pvbm_done) next_state = MC_INV_NTT;
        else next_state = MC_POLYVEC_BASEMUL;
      end

      MC_INV_NTT: begin
        if (inv_ntt_done) begin
          next_state = MC_IDLE;
          valid = 1;
        end else next_state = MC_INV_NTT;
      end

      default: next_state = MC_IDLE;
    endcase
  end

  // Sequetial block for main_computation
  always_ff @(posedge clk) begin
    if (reset) begin
      current_state <= MC_IDLE;
    end else begin
      current_state <= next_state;
      if (mode == ENC) begin
        case (current_state)
          MC_IDLE: begin
          end
          MC_LOAD_RAM: begin
          end
          MC_NTT: begin

          end
          MC_POLYVEC_BASEMUL: begin

          end
          MC_INV_NTT: begin

          end
          default: begin
          end
        endcase
      end
    end
  end

  // **************************************************
  // LOAD RAM
  // **************************************************
  mc_lr_state_e lr_current_state, lr_next_state;
  logic [5:0] lr_count;  // count from 0 - 63 to cover all the index
  logic [7:0] lr_net_in_index[4];

  // choosing input from net from pre_encrpytion to each ram
  assign lr_ram_addra = lr_count * 2;
  assign lr_ram_addrb = lr_count * 2 + 1;
  // index of net is increment and addresss as lr_ram_addr[a,b]

  generate
    // first track the index of net list in (mostly treat as 1D array size 256)
    // iterate 4 indices per round = 2 ram_addr(a, b);
    for (i = 0; i < 4; i++) begin : g_parallel_in_addr
      assign lr_net_in_index[i] = (lr_ram_addra * 2) + i;
    end

    // assign for polynomial A_t
    for (i = 0; i < 9; i++) begin : g_lr_din_at
      assign lr_ram_dina[i] = {a_t[i][lr_net_in_index[1]], a_t[i][lr_net_in_index[0]]};
      assign lr_ram_dinb[i] = {a_t[i][lr_net_in_index[3]], a_t[i][lr_net_in_index[2]]};
    end

    // assign for polynomial t_vec
    for (i = 0; i < 3; i++) begin : g_lr_din_t_vec
      assign lr_ram_dina[i+9] = {
        t_vec_transform[i][lr_net_in_index[1]], t_vec_transform[i][lr_net_in_index[0]]
      };
      assign lr_ram_dinb[i+9] = {
        t_vec_transform[i][lr_net_in_index[3]], t_vec_transform[i][lr_net_in_index[2]]
      };
    end

    // assign for error polynomial r
    for (i = 0; i < 3; i++) begin : g_lr_din_r
      assign lr_ram_dina[i+12] = {r[i][lr_net_in_index[1]], r[i][lr_net_in_index[0]]};
      assign lr_ram_dinb[i+12] = {r[i][lr_net_in_index[3]], r[i][lr_net_in_index[2]]};
    end
  endgenerate

  always_comb begin
    // Load Ram FSM
    lr_next_state = MC_LR_IDLE;
    lr_done = 0;
    lr_ram_en = 0;
    lr_ram_we = 0;
    case (lr_current_state)
      MC_LR_IDLE: begin
        if (lr_start) lr_next_state = MC_LR_START;
      end
      MC_LR_START: begin  // Start computing the first addr
        lr_ram_en = 1;
        lr_ram_we = 1;
        lr_next_state = MC_LR_LOAD;
      end
      MC_LR_LOAD: begin
        lr_next_state = MC_LR_LOAD;
        lr_ram_en = 1;
        lr_ram_we = 1;
        if (lr_count == 63) begin
          lr_next_state = MC_LR_DONE;
        end
      end
      MC_LR_DONE: begin
        lr_done = 1;
      end
      default: lr_next_state = MC_LR_IDLE;
    endcase
  end

  // always_ff for loadram
  always_ff @(posedge clk) begin
    lr_current_state = lr_next_state;
    case (lr_current_state)
      MC_LR_IDLE: begin
        lr_count <= 6'd0;
      end
      MC_LR_START: ;
      MC_LR_LOAD: begin
        if (lr_count < 6'd63) begin
          lr_count <= lr_count + 1;
        end
      end
      MC_LR_DONE: ;
      default: lr_count <= 0;
    endcase
  end

  // **************************************************
  // NTT
  // **************************************************

  always_comb begin
    // default state
    ntt_next_state = MC_NTT_IDLE;
    ntt_enable = 0;
    ntt_done = 0;
    ntt_ram_we[0] = 0;
    ntt_ram_we[1] = 0;
    ntt_ram_we[2] = 0;
    ntt_ram_en[0] = 0;
    ntt_ram_en[1] = 0;
    ntt_ram_en[2] = 0;
    case (ntt_current_state)
      MC_NTT_IDLE: begin
        if (ntt_start) begin
          ntt_next_state = MC_NTT_0;
          ntt_enable = 1;
        end
      end

      MC_NTT_0: begin
        ntt_ram_we[0] = ntt_ram_we_predec;
        ntt_ram_en[0] = ntt_ram_en_predec;
        if (ntt_valid) begin
          ntt_next_state = MC_NTT_1;
          ntt_enable = 1;
        end else ntt_next_state = MC_NTT_0;
      end

      MC_NTT_1: begin
        ntt_ram_we[1] = ntt_ram_we_predec;
        ntt_ram_en[1] = ntt_ram_en_predec;
        if (ntt_valid) begin
          ntt_next_state = MC_NTT_2;
          ntt_enable = 1;
        end else ntt_next_state = MC_NTT_1;
      end

      MC_NTT_2: begin
        ntt_ram_we[2] = ntt_ram_we_predec;
        ntt_ram_en[2] = ntt_ram_en_predec;
        if (ntt_valid) begin
          ntt_next_state = MC_NTT_DONE;
        end else ntt_next_state = MC_NTT_2;
      end
      MC_NTT_DONE: begin
        ntt_done = 1;
        ntt_next_state = MC_NTT_IDLE;
      end
      default: ntt_next_state = MC_NTT_IDLE;
    endcase
  end

  always_ff @(posedge clk) begin
    ntt_current_state <= ntt_next_state;
  end

  // **************************************************
  // Polyvec_basemul_montgomery
  // **************************************************
  always_comb begin
    pvbm_next_state = MC_PVBM_IDLE;
    pvbm_enable = 0;
    pvbm_done = 0;

    pvbm_ram_en[0] = '0;
    pvbm_ram_en[1] = '0;
    pvbm_ram_en[2] = '0;
    pvbm_ram_en[3] = '0;
    pvbm_ram_en[4] = '0;
    pvbm_ram_en[5] = '0;
    pvbm_ram_en[6] = '0;
    pvbm_ram_en[7] = '0;
    pvbm_ram_en[8] = '0;
    pvbm_ram_en[9] = '0;
    pvbm_ram_en[10] = '0;
    pvbm_ram_en[11] = '0;
    pvbm_ram_en[12] = '0;
    pvbm_ram_en[13] = '0;
    pvbm_ram_en[14] = '0;

    pvbm_ram_we[0] = '0;
    pvbm_ram_we[1] = '0;
    pvbm_ram_we[2] = '0;
    pvbm_ram_we[3] = '0;

    case (pvbm_current_state)
      MC_PVBM_IDLE: begin
        if (pvbm_start) begin
          pvbm_next_state = MC_PVBM_AT0;
          pvbm_enable = 1;
        end
      end
      MC_PVBM_AT0: begin
        pvbm_ram_en[0]  = pvbm_ram_en_predec;
        pvbm_ram_en[1]  = pvbm_ram_en_predec;
        pvbm_ram_en[2]  = pvbm_ram_en_predec;
        pvbm_ram_en[12] = pvbm_ram_en_predec;
        pvbm_ram_en[13] = pvbm_ram_en_predec;
        pvbm_ram_en[14] = pvbm_ram_en_predec;
        pvbm_ram_we[0]  = pvbm_ram_we_predec;
        if (pvbm_valid) begin
          pvbm_enable = 1;
          pvbm_next_state = MC_PVBM_AT1;
        end else pvbm_next_state = MC_PVBM_AT0;
      end
      MC_PVBM_AT1: begin
        pvbm_ram_en[3]  = pvbm_ram_en_predec;
        pvbm_ram_en[4]  = pvbm_ram_en_predec;
        pvbm_ram_en[5]  = pvbm_ram_en_predec;
        pvbm_ram_en[12] = pvbm_ram_en_predec;
        pvbm_ram_en[13] = pvbm_ram_en_predec;
        pvbm_ram_en[14] = pvbm_ram_en_predec;
        pvbm_ram_we[1]  = pvbm_ram_we_predec;
        if (pvbm_valid) begin
          pvbm_enable = 1;
          pvbm_next_state = MC_PVBM_AT2;
        end else pvbm_next_state = MC_PVBM_AT1;
      end
      MC_PVBM_AT2: begin
        pvbm_ram_en[6]  = pvbm_ram_en_predec;
        pvbm_ram_en[7]  = pvbm_ram_en_predec;
        pvbm_ram_en[8]  = pvbm_ram_en_predec;
        pvbm_ram_en[12] = pvbm_ram_en_predec;
        pvbm_ram_en[13] = pvbm_ram_en_predec;
        pvbm_ram_en[14] = pvbm_ram_en_predec;
        pvbm_ram_we[2]  = pvbm_ram_we_predec;
        if (pvbm_valid) begin
          pvbm_enable = 1;
          pvbm_next_state = MC_PVBM_TVEC;
        end else pvbm_next_state = MC_PVBM_AT2;
      end

      MC_PVBM_TVEC: begin
        pvbm_ram_en[9]  = pvbm_ram_en_predec;
        pvbm_ram_en[10] = pvbm_ram_en_predec;
        pvbm_ram_en[11] = pvbm_ram_en_predec;
        pvbm_ram_en[12] = pvbm_ram_en_predec;
        pvbm_ram_en[13] = pvbm_ram_en_predec;
        pvbm_ram_en[14] = pvbm_ram_en_predec;
        pvbm_ram_we[3]  = pvbm_ram_we_predec;
        if (pvbm_valid) pvbm_next_state = MC_PVBM_DONE;
        else pvbm_next_state = MC_PVBM_TVEC;
      end
      MC_PVBM_DONE: begin
        pvbm_done = 1;
        pvbm_next_state = MC_PVBM_IDLE;
      end
      default: ;
    endcase
  end

  always_ff @(posedge clk) begin
    pvbm_current_state = pvbm_next_state;
  end

  // **************************************************
  // INV_NTT
  // **************************************************

  always_comb begin
  end

  always_ff @(posedge clk) begin
  end
endmodule
