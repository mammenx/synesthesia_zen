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
  parameter P_GPU_SRAM_ADDR_W = 19;
  parameter P_GPU_SRAM_DATA_W = 8;
  parameter P_RGB_RES   = 4;
  parameter P_LUM_W     = 4;
  parameter P_CHRM_W    = 2;
  parameter P_HUE_W     = 3;
  parameter P_SATURATION_W  = 2;
  parameter P_INTENSITY_W   = 3;
  parameter P_PXL_HSI_W = P_HUE_W + P_SATURATION_W  + P_INTENSITY_W;
  parameter P_X_W       = $clog2(P_CANVAS_W);
  //parameter P_Y_W       = $clog2(P_CANVAS_H);
  parameter P_Y_W       = $clog2(((2**P_GPU_SRAM_ADDR_W)*P_GPU_SRAM_DATA_W) / (P_CANVAS_W*P_PXL_HSI_W));

  //RGB pixel stucture
  typedef struct  packed  {
    logic [P_RGB_RES-1:0] red;
    logic [P_RGB_RES-1:0] green;
    logic [P_RGB_RES-1:0] blue;

  } pxl_rgb_t;

  //YCbCr pixel stucture
  typedef struct  packed  {
    logic [P_LUM_W-1:0]   y;
    logic [P_CHRM_W-1:0]  cb;
    logic [P_CHRM_W-1:0]  cr;

  } pxl_ycbcr_t;


  //HSI pixel structure
  typedef struct  packed  {
    logic [P_HUE_W-1:0]         h;
    logic [P_SATURATION_W-1:0]  s;
    logic [P_INTENSITY_W-1:0]   i;
  } pxl_hsi_t;

  //Point structure
  typedef struct  packed  {
    logic [P_X_W-1:0] x;
    logic [P_Y_W-1:0] y;
  } point_t;


  //Opcode for shape
  typedef enum  logic [1:0] { LINE    = 2'd0,
                              BEZIER  = 2'd1
                            } shape_t;

  //Opcode for type of job
  typedef enum  logic [1:0] { DRAW    = 2'd0,
                              FILL    = 2'd1,
                              MULBRY  = 2'd2,
                              DEBUG   = 2'd3    //For host access to frame buffer
                            } action_t;


  //Structure describing GPU draw job
  typedef struct  packed  {
    shape_t           shape;
    logic [P_X_W-1:0] x0;
    logic [P_Y_W-1:0] y0; //Line  ->  Start of line,  Bezier ->  P0
    logic [P_X_W-1:0] x1;
    logic [P_Y_W-1:0] y1; //Line  ->  End of line,    Bezier ->  P1
    logic [P_X_W-1:0] x2;
    logic [P_Y_W-1:0] y2; //                          Bezier ->  P2
    //pxl_ycbcr_t       color;
    pxl_hsi_t         color;
    logic [3:0]       bzdepth;  //Depth of Bezier algorithm; the Bz curve will be broken down to ~2^bzdepth lines

  } gpu_draw_job_t;

  parameter P_GPU_DRAW_JOB_BFFR_W = 2 + (3*(P_X_W + P_Y_W)) + (P_LUM_W  + P_CHRM_W  + P_CHRM_W) + 4;


  //Structure describing GPU Fill Job
  typedef struct  packed  {
    //pxl_ycbcr_t       fill_color;   //Color To fill
    //pxl_ycbcr_t       line_color;   //Color of line, to detect boundaries
    pxl_hsi_t         fill_color;   //Color To fill
    pxl_hsi_t         line_color;   //Color of line, to detect boundaries
    logic [P_X_W-1:0] x0;           //Starting point, X axis
    logic [P_Y_W-1:0] y0;           //Starting point, Y axis

  } gpu_fill_job_t;

  //Structure describing Host access job
  typedef struct  packed  {
    logic             read_n_write; //1->Read, 0->Write
    logic [P_X_W-1:0] x;
    logic [P_Y_W-1:0] y;
    pxl_hsi_t         pxl;
  } host_acc_job_t;

  parameter P_GPU_FILL_JOB_BFFR_W = 2*(P_LUM_W  + P_CHRM_W  + P_CHRM_W) + (P_X_W  + P_Y_W);


  parameter P_GPU_JOB_BFFR_W  = (P_GPU_DRAW_JOB_BFFR_W  > P_GPU_FILL_JOB_BFFR_W)  ? P_GPU_DRAW_JOB_BFFR_W + 2
                                                                                  : P_GPU_FILL_JOB_BFFR_W + 2;


  //Parameters for Mulberry Bus
  parameter P_NUM_MASTERS = 2;

  typedef enum  logic [$clog2(P_NUM_MASTERS+1)-1:0] { MID_IDLE={$clog2(P_NUM_MASTERS+1){1'b0}}, //used for idle condition
                                                      MID_GPU_LB,
                                                      MID_GPU_CORE
                                                    } mid_t;  //Master ID type

  parameter P_NUM_SLAVES  = 3;

  typedef enum  logic [$clog2(P_NUM_SLAVES+1)-1:0]  { SID_IDLE={$clog2(P_NUM_SLAVES+1){1'b0}}, //used for idle condition
                                                      SID_RAND,
                                                      SID_MUL,
                                                      SID_DIV
                                                    } sid_t;

  function  sid_t decode_sid(input  logic[$clog2(P_NUM_SLAVES+1)-1:0] val);
    if(val  ==  'd0)
      return  SID_IDLE;
    else if(val ==  'd1)
      return  SID_RAND;
    else if(val ==  'd2)
      return  SID_MUL;
    else
      return  SID_DIV;
  endfunction

endpackage  //  syn_gpu_pkg
