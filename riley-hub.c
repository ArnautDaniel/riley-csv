
#include <stdlib.h>
#include <stdio.h>
#include  <ctype.h>
#include <unistd.h>
#include <linux/limits.h>
#include <string.h>

void print_usage(char** argv) {
  printf("%s path [-cpb]\n-c \t generate a iif file from an excel file\n-p \t generate a pdf file from an excel file\n-b \t do both of the above\n", argv[0]);
  return;
}

void run_factor(char*  runtime, int flag){
  char factor[PATH_MAX];
  strcpy(factor, "./riley-csv ");
  strcat(factor, runtime);
  if (flag == 1){
    strcat(factor, " -1");
  }
  if (flag == 2){
    strcat(factor, " -2");
  }
  
  system(factor);
  return;
}

void run_racket(char** argv){
  char racket[PATH_MAX];
  strcpy(racket, "./riley-pdf ");
  strcat(racket, argv[2]);
  system(racket);
  return;
}
	 
int main (int argc, char **argv) {
  int cflag = 0;
  int pflag = 0;
  int bflag = 0;
  char *cvalue = NULL;
  int index;
  opterr = 0;
  int d;
  char runtime[PATH_MAX];
  strcpy(runtime, argv[1]);
  
  printf("\n%s\n", argv[1]);
  while ((d = getopt (argc, argv, "cpb:")) != -1){
    switch (d) {
    case 'c':
      cflag = 1;
      break;
    case 'p':
      pflag = 1;
      break;
    case 'h':
      cflag = 2;
      break;
    case 'b':
      bflag = 1;
      break;
    default:
      print_usage(argv);
      exit(-1);
    }
  }
  if (bflag == 1){
    cflag = 1;
    pflag = 1;
  }
  
  if (cflag == 1){
    run_factor(runtime, cflag);
  }
  
  /*  if (pflag == 1){
      run_racket(argv);
      }*/
  
  exit(1);
}

  
  
	
