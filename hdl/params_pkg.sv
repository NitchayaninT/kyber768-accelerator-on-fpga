package params_pkg;
  localparam int KYBER_K = 3;
  localparam int KYBER_N = 256;
  localparam int KYBER_Q = 3329;
  localparam int KYBER_ETA = 2;
  localparam int KYBER_DU = 10;
  localparam int KYBER_DV = 4;
  localparam int KYBER_RQ_WIDTH = 12;
  localparam int KYBER_POLY_WIDTH = 16;
  localparam int KYBER_SPOLY_WIDTH = 3;

  localparam int SHAKE_RATE = 1344;
  localparam int SHAKE_CAPACITY = 256;
  localparam byte SHAKE_DOMAIN_SEPERATOR = 8'h1F;
  localparam int ROUND_CONSTANT = 24;

  localparam int MONTGOMERY_R = 4096;

  // MC = Main Computation
  localparam int MC_RAM_ADDR_BITS = 7;
  localparam int MC_ZETA_ADDR_BITS = 7;

  localparam int MAX_RATE_BYTES = 168;
endpackage
