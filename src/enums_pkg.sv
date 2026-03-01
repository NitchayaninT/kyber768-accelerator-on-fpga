package enums_pkg;

  typedef enum logic [2:0] {
    MC_IDLE,
    MC_LOAD_RAM,
    MC_NTT,
    MC_POLYVEC_BASEMUL,
    MC_INV_NTT,
    MC_WRITE_OUT
  } main_compute_state_e;

  typedef enum logic {
    ENC,
    DEC
  } main_compute_mode_e;

  typedef enum logic {
    NTT,
    INV_NTT
  } ntt_mode_e;
endpackage
