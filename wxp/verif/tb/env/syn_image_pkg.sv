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
  import  syn_gpu_pkg::P_RGB_RES;
  import  syn_gpu_pkg::P_LUM_W;
  import  syn_gpu_pkg::P_CHRM_W;
  import  syn_gpu_pkg::pxl_rgb_t;
  import  syn_gpu_pkg::pxl_ycbcr_t;

  //This function creates a .ppm image file with the RGB values
  import "DPI-C" pure function int  syn_dump_ppm(
                                                  input string fname,
                                                  input int width,
                                                  input int depth,
                                                  input byte unsigned red[],
                                                  input byte unsigned green[],
                                                  input byte unsigned blue[]
                                                );

  //This function creates a .raw image file with the RGB values
  import "DPI-C" pure function int  syn_dump_raw(
                                                  input string fname,
                                                  input int width,
                                                  input int depth,
                                                  input byte unsigned red[],
                                                  input byte unsigned green[],
                                                  input byte unsigned blue[]
                                                );

  //Function to convert from YCbCr->RGB
  function  pxl_rgb_t convert_ycbcr2rgb(input pxl_ycbcr_t pxl_in);
    pxl_rgb_t pxl_out;
    real      y1,cb1,cr1;
    real      r,g,b;

    //apply ycbcr normalisation
    y1  = 16  + (pxl_in.y   * 14.6);
    cb1 = 16  + (pxl_in.cb  * 74.66667);
    cr1 = 16  + (pxl_in.cr  * 74.66667);

    //apply ITU-R BT.709 conversion matrix
    r = (1.164*(y1-16)) + (1.793*(cr1-128));
    g = (1.164*(y1-16)) - (0.213*(cb1-128)) - (0.533*(cr1-128));
    b = (1.164*(y1-16)) + (2.112*(cb1-128));

    //apply RGB normalization
    r = r/16;
    g = g/16;
    b = b/16;

    //limit values between 0:15
    if(r>15)  r = 15; else if(r<0)  r = 0;
    if(g>15)  g = 15; else if(g<0)  g = 0;
    if(b>15)  b = 15; else if(b<0)  b = 0;


    //pack into rgb pxl struct
    $cast(pxl_out.red,    r);
    $cast(pxl_out.green,  g);
    $cast(pxl_out.blue,   b);

    return  pxl_out;

  endfunction : convert_ycbcr2rgb


endpackage  //  syn_image_pkg
