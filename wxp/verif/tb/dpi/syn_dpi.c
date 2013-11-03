/*
 --------------------------------------------------------------------------
   Synesthesia - Copyright (C) 2012 Gregory Matthew James.

   This file is part of Synesthesia.

   Synesthesia is free; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   Synesthesia is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------
 -- Project Code      : synesthesia
 -- File Name         : syn_dpi.c
 -- Author            : mammenx
 -- Function          : This is the gateway to access all the C functions
                        used in synesthesia via SV DPI.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "svdpi.h"
#include "syn_dpi.h"
#include "ppm.h"
#include "raw.h"
#include "fft.h"

double
syn_cos(
    double rTheta){
  return  cos(rTheta);
}

double
syn_log(
    double rVal){
  return  log(rVal);
}

double
syn_log10(
    double rVal){
  return  log10(rVal);
}

double
syn_sin(
    double rTheta){
  return  sin(rTheta);
}

double
syn_tan(
    double rTheta){
  return  tan(rTheta);
}

double
syn_acos(
    double rTheta){
  return  acos(rTheta);
}

double
syn_asin(
    double rTheta){
  return  asin(rTheta);
}

double
syn_atan(
    double rTheta){
  return  atan(rTheta);
}

double
syn_sqrt(
    double rVal){
  return  sqrt(rVal);
}

int
syn_abs(
    int num){
  return abs(num);
}

/*  Complex data type  */
typedef struct {int re; int im;} complex_t;

//function for calculating absaloute value of a complex array
void  syn_calc_complex_abs(int size, const svOpenArrayHandle complex_arry_real, const svOpenArrayHandle complex_arry_im)
{
  int i;
  double  * c_arry_re_ptr;
  double  * c_arry_im_ptr;

  c_arry_re_ptr  = (double  *)svGetArrayPtr(complex_arry_real);
  c_arry_im_ptr  = (double  *)svGetArrayPtr(complex_arry_im);

  for(i=0;i<size;i++) {
    //  printf("[syn_calc_abs - C] i : %d\tre : %f\t",i,c_arry_re_ptr[i]);

    //abs vaure is stored in real part
    c_arry_re_ptr[i] = sqrt((c_arry_re_ptr[i] * c_arry_re_ptr[i]) + (c_arry_im_ptr[i] * c_arry_im_ptr[i]));

    //  printf("im : %f\t abs : %f\n",c_arry_im_ptr[i],c_arry_re_ptr[i]);
  }

  return;
}


//dump_ppm wrapper
int syn_dump_ppm(
    const char* fname,
    int width,
    int depth,
    const svOpenArrayHandle red,
    const svOpenArrayHandle green,
    const svOpenArrayHandle blue)
{

  int i;
  unsigned  char  *red_arry_ptr;
  unsigned  char  *green_arry_ptr;
  unsigned  char  *blue_arry_ptr;

  red_arry_ptr    = malloc((width*depth)*sizeof(unsigned char));
  green_arry_ptr  = malloc((width*depth)*sizeof(unsigned char));
  blue_arry_ptr   = malloc((width*depth)*sizeof(unsigned char));

  //Convert from svOpenArrayHandle type to unsigned char type
  for (i= svLeft(red,1); i <= svRight(red,1); i++) {
      red_arry_ptr[i] = *(unsigned char*)svGetArrElemPtr1(red, i);
  }
  
  for (i= svLeft(green,1); i <= svRight(green,1); i++) {
      green_arry_ptr[i] = *(unsigned char*)svGetArrElemPtr1(green, i);
  }

  for (i= svLeft(blue,1); i <= svRight(blue,1); i++) {
      blue_arry_ptr[i] = *(unsigned char*)svGetArrElemPtr1(blue, i);
  }


  return  dump_ppm(
                    fname,
                    width,
                    depth,
                    red_arry_ptr,
                    green_arry_ptr,
                    blue_arry_ptr
                  );
}

//dump_raw wrapper
int syn_dump_raw(
    const char* fname,
    int width,
    int depth,
    const svOpenArrayHandle red,
    const svOpenArrayHandle green,
    const svOpenArrayHandle blue)
{

  int i;
  unsigned  char  *red_arry_ptr;
  unsigned  char  *green_arry_ptr;
  unsigned  char  *blue_arry_ptr;

  printf("[syn_dump_raw] fname : %s\twidth : %1d\tdepth : %1d\n",fname,width,depth);

  red_arry_ptr    = malloc((width*depth)*sizeof(unsigned char));
  green_arry_ptr  = malloc((width*depth)*sizeof(unsigned char));
  blue_arry_ptr   = malloc((width*depth)*sizeof(unsigned char));

  //Convert from svOpenArrayHandle type to unsigned char type
  for (i= svLeft(red,1); i <= svRight(red,1); i++) {
      red_arry_ptr[i] = *(unsigned char*)svGetArrElemPtr1(red, i);
  }
  
  for (i= svLeft(green,1); i <= svRight(green,1); i++) {
      green_arry_ptr[i] = *(unsigned char*)svGetArrElemPtr1(green, i);
  }

  for (i= svLeft(blue,1); i <= svRight(blue,1); i++) {
      blue_arry_ptr[i] = *(unsigned char*)svGetArrElemPtr1(blue, i);
  }


  return  dump_raw(
                    fname,
                    width,
                    depth,
                    red_arry_ptr,
                    green_arry_ptr,
                    blue_arry_ptr
                  );

}

//Calculate the pixel shade based on distance & normalization parameters
double  syn_calc_shade(
    int distance,
    int norm,
    int color)
{
  double  res;

  printf("dist : %1d, norm : %1d, color : %1d | ",distance,norm,color);

  res = (double)(norm)  - (double)(distance);
  printf("res : %f | ",res);
  res = res/((double)(norm));
  printf("res : %f | ",res);
  res = res * (double)(color);
  printf("res : %f\n",res);

  return  res;
}

/*  Wrapper for calculating FFT */
//  SV Data Types -     int                             real[]                                real[]                              real[]
void syn_calc_fft(int num_samples,  const svOpenArrayHandle data_in_arry, const svOpenArrayHandle data_out_re_arry, const svOpenArrayHandle data_out_im_arry)
{
  int i;
  double (*x)[2];   /* pointer to time-domain samples */
  double (*X)[2];   /* pointer to frequency-domain samples */


  x = malloc(2 * num_samples  * sizeof(double));
  X = malloc(2 * num_samples  * sizeof(double));



  printf("\n \n Data In Array Left %d, Data In Array Right %d \n\n", svLeft(data_in_arry,1), svRight(data_in_arry, 1) );
  for (i= svLeft(data_in_arry,1); i <= svRight(data_in_arry,1); i++) {  //packing to double type
      x[i][0] = *(double*)svGetArrElemPtr1(data_in_arry, i);
      x[i][1] = 0;

      //printf("[syn_calc_fft - C] i :%d\treal : %f\tim : %f\n",i,x[i][0],x[i][1]);
  }

  /* Calculate FFT. */
  fft(num_samples, x, X);

  printf("\n \n Data Out Real Array Left %d, Data Out Real Array Right %d \n\n", svLeft(data_out_re_arry,1), svRight(data_out_re_arry, 1) );
  for(i= svLeft(data_out_re_arry,1); i <= svRight(data_out_re_arry,1); i++) { //packing real arry
    *(double*)svGetArrElemPtr1(data_out_re_arry, i) = X[i][0];
  }

  printf("\n \n Data Out Imaginary Array Left %d, Data Out Imaginary Array Right %d \n\n", svLeft(data_out_im_arry,1), svRight(data_out_im_arry, 1) );
  for(i= svLeft(data_out_im_arry,1); i <= svRight(data_out_im_arry,1); i++) { //packing im arry
    *(double*)svGetArrElemPtr1(data_out_im_arry, i) = X[i][1];
  }

  //    for(i=0;i<num_samples;i++)  {
  //      printf("[syn_calc_fft - C] i :%d\treal : %f\tim : %f\n",i,X[i][0],X[i][1]);
  //    }

  return;
}
