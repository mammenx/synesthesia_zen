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
 -- Project Code      : synesthesia_zen
 -- Header Name       : graphics.h
 -- Author            : mammenx
 -- Description       : 
 --------------------------------------------------------------------------
*/

#include "alt_types.h"


#ifndef GRAPHICS_H_
#define GRAPHICS_H_

#define	CANVAS_W	640
#define	CANVAS_H	480

#define	RGB_RES_W	4

#define	HUE_W			3
#define	SATURATION_W	2
#define	INTENSITY_W		3

#define	X_W		10
#define	Y_W		9

//RBG Pixel Structure
typedef struct {
	alt_u8	red;
	alt_u8  green;
	alt_u8  blue;
} RGB_PXL_T;

//HSI Pixel Structure
typedef	struct {
	alt_u8 h;
	alt_u8 s;
	alt_u8 i;
} HSI_PXL_T;

#define PACK_HSI_PXL(pxl)	\
	((pxl).h << (SATURATION_W+INTENSITY_W)) + ((pxl).s << INTENSITY_W) + ((pxl).i)

//Pixel Pointer Structure
typedef struct {
	alt_u16 x;
	alt_u16 y;
} PXL_PTR_T;

//Opcodes
typedef enum {
	LINE=0,
	BEZIER=1
} SHAPE_T;

typedef enum {
	DRAW=0,
	FILL=1,
	MULBERRY=2,
	DEBUG=3
} ACTION_T;

//Draw Jobs
typedef struct {
	PXL_PTR_T	start;
	PXL_PTR_T	end;
	HSI_PXL_T	color;
} GPU_DRAW_LINE_JOB_T;

typedef struct {
	PXL_PTR_T	p0;
	PXL_PTR_T	p1;
	PXL_PTR_T	p2;
	HSI_PXL_T	color;
	alt_u8		depth;
} GPU_DRAW_BEZIER_T;

//Fill Job
typedef struct {
	HSI_PXL_T	fill_color;
	HSI_PXL_T	line_color;
	PXL_PTR_T	seed;
} GPU_FILL_JOB_T;

//Host Access Job
typedef enum {
	READ=1,
	WRITE=0
} GPU_HST_ACC_ACTION_T;

typedef struct {
	GPU_HST_ACC_ACTION_T 	action;
	PXL_PTR_T				ptr;
	HSI_PXL_T				color;
} GPU_HST_ACC_JOB_T;

//HSI->RGB Conversion Table
static RGB_PXL_T hsi2rgb[256] =
	{					/*I=0*/		/*I=1*/			/*I=2*/			/*I=3*/			/*I=4*/			/*I=5*/			/*I=6*/			/*I=7*/
		/*H=0, S=0*/  {0,0,0},		{1,1,1},		{3,3,3},		{5,5,5},		{7,7,7},		{9,9,9},		{11,11,11},		{13,13,13},
		/*H=0, S=1*/  {0,0,0},		{2,1,1},		{5,2,2},		{8,4,4},		{11,5,5},		{14,7,7},		{15,8,8},		{15,10,10},
		/*H=0, S=2*/  {0,0,0},		{3,0,0},		{7,1,1},		{11,2,2},		{15,3,3},		{15,4,4},		{15,5,5},		{15,6,6},
		/*H=0, S=3*/  {0,0,0},		{4,0,0},		{9,0,0},		{14,1,1},		{15,1,1},		{15,2,2},		{15,2,2},		{15,3,3},
		/*H=1, S=0*/  {0,0,0},		{1,1,1},		{3,3,3},		{5,5,5},		{7,7,7},		{9,9,9},		{11,11,11},		{13,13,13},
		/*H=1, S=1*/  {0,0,0},		{2,2,1},		{4,4,2},		{7,6,4},		{9,8,5},		{11,10,7},		{14,12,8},		{15,14,10},
		/*H=1, S=2*/  {0,0,0},		{2,2,0},		{5,4,1},		{8,6,2},		{10,9,3},		{13,11,4},		{15,13,5},		{15,15,6},
		/*H=1, S=3*/  {0,0,0},		{3,2,0},		{6,4,0},		{9,7,1},		{12,9,1},		{15,11,2},		{15,14,2},		{15,15,3},
		/*H=2, S=0*/  {0,0,0},		{1,1,1},		{3,3,3},		{5,5,5},		{7,7,7},		{9,9,9},		{11,11,11},		{13,13,13},
		/*H=2, S=1*/  {0,0,0},		{1,2,1},		{3,4,2},		{5,7,4},		{7,9,5},		{9,12,7},		{11,14,8},		{13,15,10},
		/*H=2, S=2*/  {0,0,0},		{1,2,0},		{3,5,1},		{5,8,2},		{7,11,3},		{9,14,4},		{11,15,5},		{13,15,6},
		/*H=2, S=3*/  {0,0,0},		{1,3,0},		{3,6,0},		{5,10,1},		{7,13,1},		{9,15,2},		{11,15,2},		{13,15,3},
		/*H=3, S=0*/  {0,0,0},		{1,1,1},		{3,3,3},		{5,5,5},		{7,7,7},		{9,9,9},		{11,11,11},		{13,13,13},
		/*H=3, S=1*/  {0,0,0},		{1,2,1},		{2,5,3},		{4,8,5},		{5,10,7},		{7,13,9},		{8,15,10},		{10,15,12},
		/*H=3, S=2*/  {0,0,0},		{0,3,1},		{1,6,3},		{2,10,4},		{3,13,6},		{4,15,8},		{5,15,9},		{6,15,11},
		/*H=3, S=3*/  {0,0,0},		{0,4,1},		{0,8,2},		{1,12,4},		{1,15,5},		{2,15,7},		{2,15,8},		{3,15,10},
		/*H=4, S=0*/  {0,0,0},		{1,1,1},		{3,3,3},		{5,5,5},		{7,7,7},		{9,9,9},		{11,11,11},		{13,13,13},
		/*H=4, S=1*/  {0,0,0},		{1,2,2},		{2,4,4},		{4,6,6},		{5,8,8},		{7,11,11},		{8,13,13},		{10,15,15},
		/*H=4, S=2*/  {0,0,0},		{0,2,2},		{1,4,4},		{2,7,7},		{3,9,9},		{4,12,12},		{5,14,14},		{6,15,15},
		/*H=4, S=3*/  {0,0,0},		{0,2,2},		{0,5,5},		{1,8,8},		{1,10,10},		{2,13,13},		{2,15,15},		{3,15,15},
		/*H=5, S=0*/  {0,0,0},		{1,1,1},		{3,3,3},		{5,5,5},		{7,7,7},		{9,9,9},		{11,11,11},		{13,13,13},
		/*H=5, S=1*/  {0,0,0},		{1,1,2},		{2,3,5},		{4,5,8},		{5,7,10},		{7,9,13},		{8,10,15},		{10,12,15},
		/*H=5, S=2*/  {0,0,0},		{0,1,3},		{1,3,6},		{2,4,10},		{3,6,13},		{4,8,15},		{5,9,15},		{6,11,15},
		/*H=5, S=3*/  {0,0,0},		{0,1,4},		{0,2,8},		{1,4,12},		{1,5,15},		{2,7,15},		{2,8,15},		{3,10,15},
		/*H=6, S=0*/  {0,0,0},		{1,1,1},		{3,3,3},		{5,5,5},		{7,7,7},		{9,9,9},		{11,11,11},		{13,13,13},
		/*H=6, S=1*/  {0,0,0},		{1,1,2},		{3,2,4},		{5,4,7},		{7,5,9},		{9,7,12},		{11,8,14},		{13,10,15},
		/*H=6, S=2*/  {0,0,0},		{1,0,2},		{3,1,5},		{5,2,8},		{7,3,11},		{9,4,14},		{11,5,15},		{13,6,15},
		/*H=6, S=3*/  {0,0,0},		{1,0,3},		{3,0,6},		{5,1,10},		{7,1,13},		{9,2,15},		{11,2,15},		{13,3,15},
		/*H=7, S=0*/  {0,0,0},		{1,1,1},		{3,3,3},		{5,5,5},		{7,7,7},		{9,9,9},		{11,11,11},		{13,13,13},
		/*H=7, S=1*/  {0,0,0},		{2,1,2},		{4,2,4},		{7,4,6},		{9,5,8},		{11,7,10},		{14,8,12},		{15,10,14},
		/*H=7, S=2*/  {0,0,0},		{2,0,2},		{5,1,4},		{8,2,6},		{10,3,9},		{13,4,11},		{15,5,13},		{15,6,15},
		/*H=7, S=3*/  {0,0,0},		{3,0,2},		{6,0,4},		{9,1,7},		{12,1,9},		{15,2,11},		{15,2,14},		{15,3,15}
	};

void enable_gpu();
void disable_gpu();
void gpu_draw_line(GPU_DRAW_LINE_JOB_T job, alt_u8 wait);
void gpu_draw_bezier(GPU_DRAW_BEZIER_T job, alt_u8 wait);
void gpu_fill(GPU_FILL_JOB_T job, alt_u8 wait);
GPU_HST_ACC_JOB_T gpu_hst_acc(GPU_HST_ACC_JOB_T job, alt_u8 wait);

#endif /* GRAPHICS_H_ */
