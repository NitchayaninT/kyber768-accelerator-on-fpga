#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void print_bin(FILE *fp, int num) {
  for (int i = 2; i >= 0; i--) {
    fprintf(fp, "%d", (num >> i) & 1);
  }
}

int gen_small(FILE *fp, int type) {
  int bin_lenght = 0;
  switch (type){
    case 1: bin_lenght = 3; break;
    case 2: bin_lenght = 12; break;
    default:
      printf("Error\n");
      return -1;
  }
  for (int i = 0; i < 256; i++) {
    int randint = (rand() % 5) - 2; // -2..2
    int binval = randint & 0x7;     // 3-bit representation
    print_bin(fp, binval);
  }
  fprintf(fp, "\n");
  return 0;
}

int main(int argc, char *argv[]) {
  int type = 0;
  while (1) {
    printf("What type of polynomial to generate?\n");
    printf("(1)Kyber Polynomial ring (2)Small polynomial\n");
    printf("Polynomial type: ");
    scanf("%d", &type);
    if (type < 1 || type > 2) {
      printf("Incorrect type!\n");
    }
    else 
      break;
  }
  char file_name[200] = "";
  char *ptr = file_name;
  printf("Enter File name : ");
  scanf("%s", ptr);
  FILE *fp = fopen(file_name, "w");
  if (!fp) {
    perror("Cannot open file");
    return 1;
  }

  int count = 0;
  srand(time(NULL));

  printf("How many small polynomial?: ");
  scanf("%d", &count);

  for (int i = 0; i < count; i++)
    gen_small(fp, type);

  fclose(fp);
  printf("Output written to %s\n", file_name);
  return 0;
}
