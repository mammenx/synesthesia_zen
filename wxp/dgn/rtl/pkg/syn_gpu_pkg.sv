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
 -- Package Name      : syn_gpu_pkg
 -- Author            : mammenx
 -- Description       : This package contains definitions of all GPU
                        related structures & types.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

package syn_gpu_pkg;

  parameter P_CANVAS_W  = 640;
  parameter P_CANVAS_H  = 480;
  parameter P_X_W       = $clog2(P_CANVAS_W);
  parameter P_Y_W       = $clog2(P_CANVAS_Y);
  parameter P_RGB_RES   = 4;

  //RGB pixel stucture
  typedef struct  {
    logic [P_RGB_RES-1:0] red;
    logic [P_RGB_RES-1:0] green;
    logic [P_RGB_RES-1:0] blue;

  } pxl_t;

  //Opcode for shape
  typedef enum  logic [1:0] { LINE    = 2'd0,
                              CIRCLE  = 2'd1
                            } shape_t;

  //Opcode for type of job
  typedef enum  logic [1:0] { DRAW    = 2'd0,
                              FILL    = 2'd1
                            } action_t;


  //Structure describing GPU job
  typedef struct  {
    shape_t           shape;
    logic [P_X_W-1:0] x1;
    logic [P_Y_W-1:0] y1; //Line  ->  Start of line,  Circle  ->  Center
    logic [P_X_W-1:0] x2;
    logic [P_Y_W-1:0] y2; //Line  ->  End of line,    Circle  ->  Radius
    pxl_t             color;
    logic [3:0]       width;  //width of shape

  } gpu_fill_job_t;

endpackage  //  syn_gpu_pkg
