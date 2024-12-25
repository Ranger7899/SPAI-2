#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "asmIIR.h"
#include "newCoefs.h"

#define SECTIONS 2     // Number of 2nd order sections
short C[SECTIONS * 5]; // Filter coefficients
                       // C[]=A[i][1], A[i][2], B[i][2], B[i][0], B[i][1]...

short w[SECTIONS*2];   // Filter delay line
                       // w[]=w[i][n-1],w[i+1][n-1],...,w[i][n-2],w[i+1][n-2],...

#define NUM_DATA 128  // Number of samples per block
short   out[NUM_DATA]; // Filter output data buffer
short   in[NUM_DATA];  // Filter input data buffer

         
void main(void)
{
  short i,k,n;
  short gainNUM, gainDEN;
  long  temp32;
  char  temp[NUM_DATA * 2];

  FILE  *fpIn,*fpOut;

  // Open file to read input data and write output data
  if ((fpIn = fopen("..\\data\\input.pcm", "rb")) == NULL)
  {
    printf("Can't open input data file\n");
    exit(0);
  }
  fpOut = fopen("..\\data\\output.pcm", "wb");


 memset(w, 0, SECTIONS * 2);

  // Get coefficients from DEN[][] and NUM[][]
  for(k=0, n=0, i=0; i < SECTIONS; i++)
  {
    gainDEN = DEN[k][0];
    gainNUM = NUM[k++][0];

    temp32 = (long) gainDEN * DEN[k][1];
    C[n++] = (short) (temp32>>14);
    temp32 = (long) gainDEN * DEN[k][2];
    C[n++] = (short) (temp32>>14);

    temp32 = (long) gainNUM * NUM[k][2];
    C[n++] = (short) (temp32>>14);
    temp32 = (long) gainNUM * NUM[k][0];
    C[n++] = (short) (temp32>>14);
    temp32 = (long) gainNUM * NUM[k++][1];
    C[n++] = (short) (temp32 >> 14);
  }

  // IIR filter experiment start 
  while (fread(temp, sizeof(char), NUM_DATA*2, fpIn) == (NUM_DATA*2))
  {
    for (k=0, i=0; i<NUM_DATA; i++)
    {
        in[i] = (temp[k] & 0xFF) | (temp[k+1] << 8);
        k += 2;
    }

    // Filter a block of samples
    asmIIR(in, NUM_DATA, out, C, SECTIONS, w);

    for (k=0, i=0; i<NUM_DATA; i++)
    {
      temp[k++] = (out[i] & 0xFF);
      temp[k++] = (out[i] >> 8) & 0xFF;
    }

    fwrite(temp, sizeof(char), NUM_DATA*2, fpOut);
  }

  fclose(fpIn);
  fclose(fpOut);
}
