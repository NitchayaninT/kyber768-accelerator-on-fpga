#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

void print_bin(FILE *fp, int num) {
  for (int i = 2; i >= 0; i--) {
    fprintf(fp, "%d", (num >> i) & 1);
  }
}


int gen(FILE *fp, int type) {
  if (type == 1) {
    for (int i = 0; i < 256;i++) {
      int randint = (rand() % 3329);
      fprintf(fp, "%03X", randint);
    }
  } else if (type == 2) {
    for (int i = 0; i < 256; i++) {
      int randint = (rand() % 5) - 2; // -2..2
      int binval = randint & 0x7;     // 3-bit representation
      print_bin(fp, binval);
    }
  }
  fprintf(fp, "\n");
  return 0;
}

int main(int argc, char *argv[]) {
  int type = 0;
  char extension[5];
  printf("What type of polynomial to generate?\n");
  while (1) {
    printf("(1) Kyber Polynomial ring (2) Small polynomial\n");
    printf("Polynomial type: ");
    scanf("%d", &type);
    if (type == 1) {
      strcpy(extension, ".hex");
      break;
    } else if (type == 2) {
      strcpy(extension, ".bin");
      break;
    } else
      printf("!Incorrect type!\n");
  }

  char file_name[200] = "";
  printf("Enter File name : ");
  scanf("%s", file_name);
  strcat(file_name, extension);
  FILE *fp = fopen(file_name, "w");
  if (!fp) {
    perror("Cannot open file");
    return 1;
  }

  int count = 0;
  srand(time(NULL));

  printf("How many polynomial?: ");
  scanf("%d", &count);

  for (int i = 0; i < count; i++)
    gen(fp, type);

  fclose(fp);
  printf("Output written to %s\n", file_name);
  return 0;
}
