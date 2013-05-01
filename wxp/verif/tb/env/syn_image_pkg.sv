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
 -- Package Name      : syn_image_pkg
 -- Author            : mammenx
 -- Description       : This package contains DPI functions related to image
                        processing tasks.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

package syn_image_pkg;

  //This function creates a .ppm image file with the RGB values
  import "DPI-C" pure function int  syn_dump_ppm(
                                                  input string fname,
                                                  input int width,
                                                  input int depth,
                                                  input byte unsigned red[],
                                                  input byte unsigned green[],
                                                  input byte unsigned blue[]
                                                );

endpackage  //  syn_image_pkg
