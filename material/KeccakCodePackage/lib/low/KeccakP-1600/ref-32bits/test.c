// test_main.c
#include "KeccakP-1600-SnP.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>

void print_state(const KeccakP1600_plain32_state *state) {
  unsigned char bytes[200];
  KeccakP1600_ExtractBytes(state, bytes, 0, 200);

  printf("State as hex (1600 bits):\n");
  for (int i = 0; i < 200; i++) {
    printf("%02x", bytes[i]);
    if ((i + 1) % 8 == 0)
      printf(" ");
    if ((i + 1) % 40 == 0)
      printf("\n");
  }
  printf("\n");
}

int main() {
  KeccakP1600_plain32_state state;

  // Initialize state to zeros
  KeccakP1600_Initialize(&state);

  // Your test input:
  // 256'hf8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598 Note:
  // This needs to be in little-endian byte order
  unsigned char input[32] = {
      0x98, 0x55, 0x66, 0xc9, 0x00, 0xf5, 0xef, 0x6d, // Bytes 0-7
      0x3f, 0x3e, 0x8a, 0xde, 0x4e, 0x9b, 0x6b, 0xa0, // Bytes 8-15
      0x7e, 0x9e, 0x43, 0xaa, 0x4a, 0x21, 0xdc, 0x4d, // Bytes 16-23
      0xa5, 0xfe, 0x4d, 0x04, 0x29, 0x12, 0xf1, 0xf8  // Bytes 24-31
  };

  // Load input into state (first 256 bits, rest is zeros)
  KeccakP1600_AddBytes(&state, input, 0, 32);

  printf("INPUT STATE:\n");
  print_state(&state);

  // Apply Keccak-f[1600] permutation (24 rounds)
  KeccakP1600_Permute_24rounds(&state);

  printf("\nOUTPUT STATE (after 24 rounds):\n");
  print_state(&state);

  return 0;
}
