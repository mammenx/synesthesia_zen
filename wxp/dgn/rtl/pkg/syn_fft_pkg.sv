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
 -- Package Name      : syn_fft_pkg
 -- Author            : mammenx
 -- Description       : This package contains all the datatypes needed for
                        FFT.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

package syn_fft_pkg;

  `define COMPLEX_STRUCT_T(WIDTH, NAME) \
    typedef struct  packed  { \
      logic [WIDTH-1:0] re; \
      logic [WIDTH-1:0] im; \
    } ``NAME``;


  parameter P_FFT_SAMPLE_W    = 32;
  parameter P_FFT_TWDL_W      = 10;
  parameter P_BUTTERFLY_RES_W = 42;

  `COMPLEX_STRUCT_T(P_FFT_SAMPLE_W, fft_sample_t)

  `COMPLEX_STRUCT_T(P_FFT_TWDL_W, fft_twdl_t)

  `COMPLEX_STRUCT_T(P_BUTTERFLY_RES_W,  butres_t)

endpackage  //  syn_fft_pkg
