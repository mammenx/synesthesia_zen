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
