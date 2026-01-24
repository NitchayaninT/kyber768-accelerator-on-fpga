#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct {
  int16_t coeff[256];
} poly;

void genpoly(int format);
void gen_msg(char *msg);
int main() {
  int format;
  printf("########################################\n");
  printf("# Kyber Test Vector Generator\n");
  printf("########################################\n\n");

  printf("Available Format\n");
  printf("1 : Polynomial 12bits coeff\n");
  printf("2 : Polynomial 16bits coeff\n");
  printf("3 : Small Polynomial 16bits coeff\n");
  printf("4 : Bitstream 256 bits\n");
  while (1) {
    printf("Choose format: ");
    if (scanf("%d", &format) == 1) {
      if (format < 5 && format > 0)
        break;
    } else
      scanf("%*s");
    printf("Invaid input! Choose [1-4] \n");
  }

  switch (format) {
  case 1:
  case 2:
  case 3: {
    poly test;

    break;
  }
  case 4: {
    char msg[64];
    gen_msg(msg);
    break;
  }
  default:;
  }

  return 0;
}

void gen_msg(char *msg) {
}
