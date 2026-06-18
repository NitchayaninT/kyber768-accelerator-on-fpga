# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SystemVerilog FPGA implementation of **Kyber768** (NIST post-quantum KEM), targeting the Arty S7-50 FPGA. The project accelerates the encryption and decryption pipelines of the Kyber768 Key Encapsulation Mechanism.

## Simulation

The project uses **Icarus Verilog** (`iverilog`/`vvp`). There is no Makefile — compile commands must be constructed manually.

General pattern to simulate a testbench:
```sh
# Compile (always include packages first, then sources, then testbench)
iverilog -g2012 \
  hdl/params_pkg.sv hdl/enums_pkg.sv \
  hdl/shared/hash/permutation/theta.sv \
  hdl/shared/hash/permutation/rho.sv \
  hdl/shared/hash/permutation/pi.sv \
  hdl/shared/hash/permutation/chi.sv \
  hdl/shared/hash/permutation/iota.sv \
  hdl/shared/hash/permutation.sv \
  hdl/shared/hash/sponge_controller.sv \
  <other_dut_sources...> \
  test/<module>_tb.sv \
  -o sim.out

# Run
vvp sim.out
```

Testbenches emit `$dumpfile("dump.vcd")`/`$dumpvars` for waveform capture.

## Architecture

### Top-level Flow

Encryption pipeline (left to right, each stage asserts `valid`/`done` to start the next):

```
pre_encryption → main_computation → add (combinational) → reduce_top → compress_encode → post_encryption
```

Decryption mirrors this with `pre_decryption → main_computation (mode=DEC) → subtract → reduce → compress_encode_dec → post_decryption`.

### Module Hierarchy

```
encryption_top.sv                    ← top encryption wrapper
├── pre_encryption.sv                ← hashing, noise gen, matrix gen
│   ├── decode_pk / decode_msg       ← byte → polynomial decoders
│   ├── public_matrix_gen → shake128 + reject_sampling
│   └── noise_gen → shake256 + cbd
├── main_computation.sv              ← NTT / PVBM / INVNTT with 15 BRAMs
│   ├── ntt.sv (+ butterfly, fqmul, montgomery_reduce, barrett_reduce)
│   ├── polyvec_basemul_montgomery.sv (→ poly_basemul_montgomery → basemul)
│   ├── rams_dp.sv                   ← dual-port BRAM primitive
│   ├── rom_zetas.sv / rom_zetas_inv.sv
├── add.sv (shared, combinational)
├── reduce_top.sv / reduce.sv (shared)
├── compress_encode_enc.sv
└── post_encryption.sv

hdl/shared/hash/
├── hash_controller.sv               ← dispatches SHA3-256/512, SHAKE128/256 requests
├── sponge_controller.sv             ← Keccak sponge FSM (one rate-block at a time)
└── permutation.sv                   ← Keccak-p[1600,24] (wraps theta/rho/pi/chi/iota)
```

### Global Packages (always import these)

- `hdl/params_pkg.sv` — Kyber768 constants: `KYBER_K=3`, `KYBER_N=256`, `KYBER_Q=3329`, `KYBER_ETA=2`, `KYBER_DU=10`, `KYBER_DV=4`, `MONTGOMERY_R=4096`
- `hdl/enums_pkg.sv` — FSM state types: `main_compute_state_e`, `main_compute_mode_e` (`ENC`/`DEC`), `ntt_mode_e`

### Hash Subsystem

`hash_controller` accepts a 2-bit `hash_mode`:
| Mode | Algorithm | Rate | Domain suffix |
|------|-----------|------|---------------|
| `00` | SHA3-256  | 136 B | `0x06` |
| `01` | SHA3-512  | 72 B  | `0x06` |
| `10` | SHAKE128  | 168 B | `0x1F` |
| `11` | SHAKE256  | 136 B | `0x1F` |

`sponge_controller` takes one rate-block at a time via `block_in_ready`/`last_block` handshake. Set `matrix_gen=1` for SHAKE128 matrix generation to trigger 3 squeeze rounds.

### Main Computation BRAM Layout

15 dual-port BRAMs shared across LOAD_RAM → NTT → POLYVEC_BASEMUL → INV_NTT stages:
- BRAMs 0–8: A transpose matrix (used in ENC only)
- BRAMs 9–11: t/s polynomial vector
- BRAMs 12–14: r/u noise polynomials

RAM address muxing is done in `always_comb` blocks inside `main_computation.sv` based on `current_state`.

### Handshake Convention

All sequential stages use: `enable` (input, start signal) → `valid`/`done` (output, completion signal). Combinational modules (add, parts of reduce) are purely combinational with no enable/valid.

## Directory Layout

- `hdl/` — RTL source (indexed by slang LSP)
- `test/` — Testbenches, mirroring `hdl/` subdirectory structure
- `constraint/` — Xilinx XDC files for Arty S7-50 (`spartan7.xdc`) and a simple clock file
- `archive/` — Deprecated modules (excluded from LSP indexing; do not edit)
- `experimental/` — Work-in-progress; not part of the main design
- `reports/` — Synthesis/implementation reports (excluded from LSP indexing)

## FPGA Target

Board: **Arty S7-50** (Xilinx Spartan-7). Synthesis/implementation uses Vivado. Clock constraint: 100 MHz (10 ns period) on `H10`.
