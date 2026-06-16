# Hash Module Optimization Log

## Files Changed

- `hdl/shared/hash/permutation.sv`
- `hdl/shared/hash/sponge_controller.sv`

---

## permutation.sv

### Change: Remove unnecessary state clear on `!enable`

**Before:**
```systemverilog
end else if (!enable) begin
  round <= 5'h00;
  valid <= 1'b0;
  state_buffer <= 1600'h0;
```

**After:**
```systemverilog
end else if (!enable) begin
  round <= 5'h00;
  valid <= 1'b0;
```

**Why:** `state_buffer` is always overwritten from `in` on the very first enabled cycle (`round == 0`), so zeroing all 1600 FFs every time `enable` drops is wasted switching power. The reset-time clear (in the `rst` branch) is kept to avoid X-propagation in simulation.

---

## sponge_controller.sv

### Change 1: Eliminate hardware divider (~200–300 LUTs saved)

**Before:**
```systemverilog
logic [7:0] absorb_idx;
logic [7:0] num_blocks;
logic [7:0] last_block;

assign num_blocks = (input_len_bytes / rate_bytes) + 1;
assign last_block = num_blocks - 1;
```

**After:**
```systemverilog
logic [15:0] absorbed_bytes;
logic        is_last_block;

assign is_last_block = (absorbed_bytes + rate_bytes > input_len_bytes);
```

**Why:** `input_len_bytes / rate_bytes` synthesizes as a 16-bit / 16-bit combinational divider — roughly 200–300 LUTs on most FPGAs. Replaced with a single 17-bit comparator (`absorbed_bytes + rate_bytes > input_len_bytes`).

The `>` is strict (not `>=`) because when `absorbed_bytes == input_len_bytes` exactly (input fills a block perfectly), the domain suffix byte must go into the *next* block, so the current block is not yet the last.

In the FSM (`PH_PERMUTE`), when the current block is not the last, `absorbed_bytes` is incremented by `rate_bytes` before transitioning — maintaining the same semantics as the old `absorb_idx + 1`.

---

### Change 2: Eliminate runtime multiplier (~60–80 LUTs saved)

**Before (in `rate_block` always_comb):**
```systemverilog
total_bytes_index = absorb_idx * rate_bytes + j;
```

**After:**
```systemverilog
total_bytes_index = absorbed_bytes + j;
```

**Why:** `absorb_idx * rate_bytes` is an 8×16-bit runtime multiply (since `rate_bytes` is a signal, not a compile-time constant). Replaced with a plain adder using `absorbed_bytes`, which is a registered accumulator that always holds `absorb_idx * rate_bytes`. No information is lost — the multiply is just pre-computed incrementally as a register.

Same replacement applied to the last-block padding condition:
```systemverilog
// Before
if ((absorb_idx == last_block) && (j == rate_bytes - 1))

// After
if (is_last_block && (j == rate_bytes - 1))
```

---

## What Was Intentionally Left Alone

### Wait states: `PH_RESET_PERMUTE` and `PH_RESET_SQUEEZE_PERMUTE`

These each add 1 cycle per non-final absorb/squeeze block. They exist because the permutation module holds `valid` high until `enable` drops, and two cycles of `enable=0` must pass before safely re-entering `PH_PERMUTE` (otherwise a stale `perm_valid=1` from the previous run causes a false completion trigger).

Eliminating them requires changing the permutation's `valid` output from **hold-high** to a **1-cycle pulse** at the end of round 24. That change is possible and would save `(num_absorb_blocks - 1) + (num_squeeze_blocks - 1)` cycles per hash call, but it would make `permutation_tb.sv` display `valid=0` when it samples at cycle 50 (cosmetically confusing, since it samples well after the pulse).

This can be done as a follow-up if the latency reduction is needed.

---

## Summary Table

| Location | Issue | Savings | Status |
|---|---|---|---|
| `permutation.sv` `!enable` branch | 1600-FF clear on every disable | switching power | Done |
| `sponge_controller.sv` L99–100 | 16-bit / 16-bit hardware divider | ~200–300 LUTs | Done |
| `sponge_controller.sv` L110 | 8×16-bit runtime multiplier | ~60–80 LUTs | Done |
| `sponge_controller.sv` `PH_RESET_*` | 2 FSM wait states | latency only | Left for follow-up |
