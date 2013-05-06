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

  //import dpi task      C Name = SV function name
  import "DPI-C" pure function real syn_cos (input real rTheta);
  import "DPI-C" pure function real syn_sin (input real rTheta);
  import "DPI-C" pure function real syn_tan (input real rTheta);
  import "DPI-C" pure function real syn_acos(input real rTheta);
  import "DPI-C" pure function real syn_asin(input real rTheta);
  import "DPI-C" pure function real syn_atan(input real rTheta);
  import "DPI-C" pure function real syn_log (input real rVal);
  import "DPI-C" pure function real syn_log10 (input real rVal);
  import "DPI-C" pure function void syn_calc_abs(input int size, inout real arry_real[], input real arry_im[]);
  import "DPI-C" pure function real syn_sqrt(input real rVal);

  const real  pi  = 3.1416;

endpackage : syn_math_pkg
