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
 -- File Name         : raw.c
 -- Author            : mammenx
 -- Function          : Contains functions to create raw image from
                        RGB data. BPM is 24.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

#include <stdio.h>
#include <stdlib.h>

#include "raw.h"

int dump_raw  (const char *fname, int width, int depth, unsigned char *red_arry, unsigned char *green_arry, unsigned char *blue_arry)
{
	  FILE  *fp;
	  int   i;

	  /*  Open new raw file */
	  fp  = fopen(fname, "w+");
	  if(!fp) return 0;

	  /*  Loop-de-Loop  */
	  for(i=0; i<(width*depth);  i++)
	  {
		  putc((int)(red_arry[i]),	fp);
		  //putc((int)(green_arry[i]),fp);
		  putc((int)(green_arry[i]),fp);
		  putc((int)(blue_arry[i]),	fp);
	  }

	  /*  Close File  */
	  fclose(fp);

	  return	1;
}
