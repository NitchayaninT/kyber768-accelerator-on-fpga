package params_pkg;
  parameter int KYBER_K = 3;
  parameter int KYBER_N = 256;
  parameter int KYBER_Q = 3329;
  parameter int KYBER_ETA = 2;
  parameter int KYBER_DU = 10;
  parameter int KYBER_DV = 4;
  parameter int KYBER_RQ_WIDTH = 12;
  parameter int KYBER_POLY_WIDTH = 16;
  parameter int KYBER_SPOLY_WIDTH = 3;

  parameter int SHAKE_RATE = 1344;
  parameter int SHAKE_CAPACITY = 256;
  parameter byte SHAKE_DOMAIN_SEPERATOR = 8'h1F;
  parameter int ROUND_CONSTANT = 24;

  parameter int MONTGOMERY_R = 4096;

  // MC = Main Computation
  parameter int MC_RAM_ADDR_BITS = 7;
  parameter int MC_ZETA_ADDR_BITS = 7;
endpackage
