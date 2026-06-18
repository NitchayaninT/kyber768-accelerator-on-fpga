# sponge_contrller.sv
- input size : one rate block at a time
- output size : one rate block at a time

## edge case
Case 1: pk hash input (SHA3-256 of 1184-byte public key)

Rate = 136 bytes → 9 absorb blocks (⌈1184/136⌉ = 9), output = 32 bytes (1 squeeze)

IDLE
→ ABSORB block 1 (136 bytes)  → PERMUTE
→ ABSORB block 2 (136 bytes)  → PERMUTE
→ ABSORB block 3 (136 bytes)  → PERMUTE
→ ...
→ ABSORB block 9 (32 bytes + padding) → PERMUTE   ← last_block here
→ SQUEEZE (take first 32 bytes from state)
→ DONE

---
Case 2: pk size output (SHAKE128 matrix generation)

Rate = 168 bytes, input = 34 bytes (1 block), output = ~504 bytes → 3 squeeze rounds

IDLE
→ ABSORB block 1 (34 bytes + padding) → PERMUTE   ← last_block here
→ SQUEEZE block 1 (168 bytes out)
→ PERMUTE
→ SQUEEZE block 2 (168 bytes out)
→ PERMUTE
→ SQUEEZE block 3 (168 bytes o
→ DONE
