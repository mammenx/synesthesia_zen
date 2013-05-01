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
 -- File Name         : ppm.c
 -- Author            : mammenx
 -- Function          : Contains functions to create raw PPM image from
                        RGB data.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

#include <stdio.h>
#include <conio.h>
#include <string.h>

#include	"ppm.h"

int dump_ppm  (const char *fname, int width, int depth, unsigned char *red_arry, unsigned char *green_arry, unsigned char *blue_arry)
{
  FILE  *fp;
  int   i;
  const	char *ext	=	".ppm";

  /*  Add .ppm file extension to file name  */
  //strcat(fname, ext);

  /*  Open new ppm file */
  fp  = fopen(fname, "w+");


  /*  Build PPM Header  */
  fprintf(fp, "P3\n");  //ASCII Portable pixmap
  fprintf(fp, "#  PPM File Name <%s>\n",  fname);
  fprintf(fp, "%d # Image Width\n", width);
  fprintf(fp, "%d # Image Depth\n", depth);
  fprintf(fp, "255\n");
  fprintf(fp, "\n#  RGB Data\n");

  /*  Loop-de-Loop  */
  for(i=0; i<(width*depth);  i++)
  {
    fprintf(fp, "%3d %3d %3d", red_arry[i], green_arry[i],  blue_arry[i]);

    if(i  &&  !(i%width))
    {
      fprintf(fp, "\n");
    }
    else
    {
      fprintf(fp, "  ");
    }
  }

  /*  Close File  */
  fclose(fp);

  return 0;
}

