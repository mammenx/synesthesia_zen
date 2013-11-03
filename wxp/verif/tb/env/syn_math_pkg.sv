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
 -- Package Name      : syn_math_pkg
 -- Author            : mammenx
 -- Description       : This package contains DPI functions related to basic
                        math & trignometric functions.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

package syn_math_pkg;

  import  syn_fft_pkg::*;

  //import dpi task      C Name = SV function name
  import "DPI-C" pure function real syn_cos (input real rTheta);
  import "DPI-C" pure function real syn_sin (input real rTheta);
  import "DPI-C" pure function real syn_tan (input real rTheta);
  import "DPI-C" pure function real syn_acos(input real rTheta);
  import "DPI-C" pure function real syn_asin(input real rTheta);
  import "DPI-C" pure function real syn_atan(input real rTheta);
  import "DPI-C" pure function real syn_log (input real rVal);
  import "DPI-C" pure function real syn_log10 (input real rVal);
  import "DPI-C" pure function void syn_calc_complex_abs(input int size, inout real arry_real[], input real arry_im[]);
  import "DPI-C" pure function real syn_sqrt(input real rVal);
  import "DPI-C" pure function int syn_abs(int num);

  const real  pi  = 3.1416;

  /*  Function to perform complex multiplication  */
  function  fft_sample_t syn_complex_mul(input fft_sample_t a, input fft_twdl_t t);
    fft_sample_t res;
    int a_re,a_im,t_re,t_im,res_re,res_im;

    $cast(a_re, a.re);
    $cast(a_im, a.im);
    $cast(t_re, {{32-P_FFT_TWDL_W{t.re[P_FFT_TWDL_W-1]}}, t.re});
    $cast(t_im, {{32-P_FFT_TWDL_W{t.im[P_FFT_TWDL_W-1]}}, t.im});

    res_re  = ((a_re * t_re) - (a_im * t_im)) / 256;
    res_im  = ((a_re * t_im) + (a_im * t_re)) / 256;

    $cast(res.re, res_re);
    $cast(res.im, res_im);

    return res;

  endfunction : syn_complex_mul

  /*  Function to perform complex addition  */
  function  fft_sample_t  syn_complex_add(input fft_sample_t a,b);
    fft_sample_t  res;
    int a_re,a_im,b_re,b_im,res_re,res_im;

    $cast(a_re,a.re);
    $cast(a_im,a.im);
    $cast(b_re,b.re);
    $cast(b_im,b.im);

    res_re  = a_re  + b_re;
    res_im  = a_im  + b_im;

    $cast(res.re, res_re);
    $cast(res.im, res_im);

    return  res;

  endfunction : syn_complex_add

  /*  Function to perform complex subtraction */
  function  fft_sample_t  syn_complex_sub(input fft_sample_t a,b);
    fft_sample_t  res;
    int a_re,a_im,b_re,b_im,res_re,res_im;

    $cast(a_re,a.re);
    $cast(a_im,a.im);
    $cast(b_re,b.re);
    $cast(b_im,b.im);

    res_re  = a_re  - b_re;
    res_im  = a_im  - b_im;

    $cast(res.re, res_re);
    $cast(res.im, res_im);

    return  res;

  endfunction : syn_complex_sub

endpackage : syn_math_pkg
