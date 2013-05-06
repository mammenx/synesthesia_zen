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
  import  syn_gpu_pkg::pxl_hsi_t;
  import  syn_math_pkg::syn_cos;
  import  syn_math_pkg::syn_acos;
  import  syn_math_pkg::syn_sqrt;
  import  syn_math_pkg::pi;

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


  //Function to convert from RGB->YCbCr
  function  pxl_ycbcr_t convert_rgb2ycbcr(input pxl_rgb_t pxl_in);
    pxl_ycbcr_t pxl_out;
    real    r1,g1,b1;
    real    y,cb,cr;

    //normalise rgb
    r1  = pxl_in.red    * 16;
    g1  = pxl_in.green  * 16;
    b1  = pxl_in.blue   * 16;

    //apply ITU-R BT.709 matrix
    y   = 16  + (0.183*r1   + 0.614*g1  + 0.062*b1);
    cb  = 128 + (-0.101*r1  - 0.339*g1  + 0.439*b1);
    cr  = 128 + (0.439*r1   - 0.399*g1  - 0.040*b1);

    //normalise ycbcr
    y   = (y-16)/14.6;
    cb  = (cb-16)/74.66667;
    cr  = (cr-16)/74.66667;

    //pack into ycbcr pxl struct
    $cast(pxl_out.y,    y);
    $cast(pxl_out.cb,   cb);
    $cast(pxl_out.cr,   cr);

    return  pxl_out;

  endfunction : convert_rgb2ycbcr

  //Function to convert HSI->RGB
  function  pxl_rgb_t convert_hsi2rgb(input pxl_hsi_t pxl_in);
    pxl_rgb_t pxl_out;
    real    r,g,b;
    real    h,s,i;
    real    h1;
    real    x,y,z;

    //normalize HSI
    h = (pxl_in.h * pi)/4;
    s = pxl_in.s  / 3;
    i = pxl_in.i  / 7;

    if(h  < (2*pi/3))
      h1  = h;
    else if(h < (4*pi/3))
      h1  = h - (2*pi/3);
    else if(h < (2*pi))
      h1  = h - (4*pi/3);

    x = i*(1-s);
    y = i*(1  + (s*syn_cos(h1))/syn_cos((pi/3) - h1) );
    z = 3*i - (x + y);

    if(h  < (2*pi/3))
    begin
      r = y;  g = z;  b = x;
    end
    else if(h < (4*pi/3))
    begin
      r = x;  g = y;  b = z;
    end
    else if(h < (2*pi))
    begin
      r = z;  g = x;  b = y;
    end

    //normalize RGB
    r = r * 15;
    g = g * 15;
    b = b * 15;

    //limit values between 0:15
    if(r>15)  r = 15; else if(r<0)  r = 0;
    if(g>15)  g = 15; else if(g<0)  g = 0;
    if(b>15)  b = 15; else if(b<0)  b = 0;

    //pack into rgb pxl struct
    $cast(pxl_out.red,    r);
    $cast(pxl_out.green,  g);
    $cast(pxl_out.blue,   b);

    return  pxl_out;

  endfunction : convert_hsi2rgb


  //Function to convert RGB->HSI
  function  pxl_hsi_t convert_rgb2hsi(input pxl_rgb_t pxl_in);
    pxl_hsi_t pxl_out;
    real    r,g,b;
    real    h,s,i;
    real    min_rgb;

    //normalize RGB
    r = pxl_in.red    / (pxl_in.red + pxl_in.green  + pxl_in.blue);
    g = pxl_in.green  / (pxl_in.red + pxl_in.green  + pxl_in.blue);
    b = pxl_in.blue   / (pxl_in.red + pxl_in.green  + pxl_in.blue);


    h = syn_acos((0.5*((r-g)+(r-b)))  / syn_sqrt((r-g)*(r-g)  + (r-b)*(g-b)));

    if(b  > g)  h = (2*pi)  - h;


    if(r  < g)
    begin
      if(r  < b)
      begin
        min_rgb = r;
      end
      else
      begin
        min_rgb = b;
      end
    end
    else
    begin
      if(g  < b)
      begin
        min_rgb = g;
      end
      else
      begin
        min_rgb = b;
      end
    end

    s = 1 - (3*min_rgb);

    i = (pxl_in.red + pxl_in.green  + pxl_in.blue)  / (3*15);


    //normalize HSI
    h = (h  * 4)/pi;
    s = s * 3;
    i = i * 7;

    //pack into hsi pxl struct
    $cast(pxl_out.h,  h);
    $cast(pxl_out.s,  s);
    $cast(pxl_out.i,  i);

    return  pxl_out;

  endfunction : convert_rgb2hsi

endpackage  //  syn_image_pkg
