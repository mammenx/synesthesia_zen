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
 -- File Name         : graphics.c
 -- Author            : mammenx
 -- Description       : 
 --------------------------------------------------------------------------
*/

#include "../cortex/vcortex/gpu/gpu.h"
#include "graphics.h"
#include "ch.h"
#include "sys/alt_stdio.h"


void enable_gpu() {
	IOWR_VCORTEX_GPU_CONTROL(VCORTEX_GPU_EN_MSK);
	return;
}

void disable_gpu() {
	IOWR_VCORTEX_GPU_CONTROL(~VCORTEX_GPU_EN_MSK);
	return;
}

void gpu_draw_line(GPU_DRAW_LINE_JOB_T job, alt_u8 wait) {
	//wait for GPU to be free
	while((IORD_VCORTEX_GPU_STATUS &(VCORTEX_GPU_STATUS_HST_ACC_DONE_MSK + \
				  	  	  	  	  	 VCORTEX_GPU_STATUS_HST_MUL_DONE_MSK + \
				  	  	  	  	  	 VCORTEX_GPU_STATUS_PICASSO_BUSY_MSK + \
				  	  	  	  	  	 VCORTEX_GPU_STATUS_EUCLID_BUSY_MSK))   \
			!= (VCORTEX_GPU_STATUS_HST_MUL_DONE_MSK+VCORTEX_GPU_STATUS_HST_ACC_DONE_MSK))
	{
		chThdSleepMilliseconds(1);
	}


	IOWR_VCORTEX_GPU_JOB_BFFR_1(LINE);
	IOWR_VCORTEX_GPU_JOB_BFFR_2(job.start.x);
	IOWR_VCORTEX_GPU_JOB_BFFR_3(job.start.y);
	IOWR_VCORTEX_GPU_JOB_BFFR_4(job.end.x);
	IOWR_VCORTEX_GPU_JOB_BFFR_5(job.end.y);
	IOWR_VCORTEX_GPU_JOB_BFFR_8(PACK_HSI_PXL(job.color));
	IOWR_VCORTEX_GPU_JOB_BFFR_0(DRAW);

	if(wait) {
		while(IORD_VCORTEX_GPU_STATUS & VCORTEX_GPU_STATUS_EUCLID_BUSY_MSK) {
			chThdSleepMilliseconds(1);
		}
	}

	return;
}

void gpu_draw_bezier(GPU_DRAW_BEZIER_T job, alt_u8 wait){
	//wait for GPU to be free
	while((IORD_VCORTEX_GPU_STATUS &(VCORTEX_GPU_STATUS_HST_ACC_DONE_MSK + \
									 VCORTEX_GPU_STATUS_HST_MUL_DONE_MSK + \
									 VCORTEX_GPU_STATUS_PICASSO_BUSY_MSK + \
									 VCORTEX_GPU_STATUS_EUCLID_BUSY_MSK))   \
			!= (VCORTEX_GPU_STATUS_HST_MUL_DONE_MSK+VCORTEX_GPU_STATUS_HST_ACC_DONE_MSK))
	{
		chThdSleepMilliseconds(1);
	}


	IOWR_VCORTEX_GPU_JOB_BFFR_1(BEZIER);
	IOWR_VCORTEX_GPU_JOB_BFFR_2(job.p0.x);
	IOWR_VCORTEX_GPU_JOB_BFFR_3(job.p0.y);
	IOWR_VCORTEX_GPU_JOB_BFFR_4(job.p1.x);
	IOWR_VCORTEX_GPU_JOB_BFFR_5(job.p1.y);
	IOWR_VCORTEX_GPU_JOB_BFFR_6(job.p2.x);
	IOWR_VCORTEX_GPU_JOB_BFFR_7(job.p2.y);
	IOWR_VCORTEX_GPU_JOB_BFFR_8(PACK_HSI_PXL(job.color));
	IOWR_VCORTEX_GPU_JOB_BFFR_9(job.depth);
	IOWR_VCORTEX_GPU_JOB_BFFR_0(DRAW);

	if(wait) {
		while(IORD_VCORTEX_GPU_STATUS & VCORTEX_GPU_STATUS_EUCLID_BUSY_MSK) {
			chThdSleepMilliseconds(1);
		}
	}

	return;
}

void gpu_fill(GPU_FILL_JOB_T job, alt_u8 wait) {
	//wait for GPU to be free
	while((IORD_VCORTEX_GPU_STATUS &(VCORTEX_GPU_STATUS_HST_ACC_DONE_MSK + \
									 VCORTEX_GPU_STATUS_HST_MUL_DONE_MSK + \
									 VCORTEX_GPU_STATUS_PICASSO_BUSY_MSK + \
									 VCORTEX_GPU_STATUS_EUCLID_BUSY_MSK))   \
			!= (VCORTEX_GPU_STATUS_HST_MUL_DONE_MSK+VCORTEX_GPU_STATUS_HST_ACC_DONE_MSK))
	{
		chThdSleepMilliseconds(1);
	}


	IOWR_VCORTEX_GPU_JOB_BFFR_1(PACK_HSI_PXL(job.fill_color));
	IOWR_VCORTEX_GPU_JOB_BFFR_2(PACK_HSI_PXL(job.line_color));
	IOWR_VCORTEX_GPU_JOB_BFFR_3(job.seed.x);
	IOWR_VCORTEX_GPU_JOB_BFFR_4(job.seed.y);
	IOWR_VCORTEX_GPU_JOB_BFFR_0(FILL);

	if(wait) {
		while(IORD_VCORTEX_GPU_STATUS & VCORTEX_GPU_STATUS_PICASSO_BUSY_MSK) {
			chThdSleepMilliseconds(1);
		}
	}

	return;
}

GPU_HST_ACC_JOB_T gpu_hst_acc(GPU_HST_ACC_JOB_T job, alt_u8 wait) {
	alt_u32 res;

	//wait for GPU to be free
	while((IORD_VCORTEX_GPU_STATUS &(VCORTEX_GPU_STATUS_HST_ACC_DONE_MSK + \
									 VCORTEX_GPU_STATUS_HST_MUL_DONE_MSK + \
									 VCORTEX_GPU_STATUS_PICASSO_BUSY_MSK + \
									 VCORTEX_GPU_STATUS_EUCLID_BUSY_MSK))   \
			!= (VCORTEX_GPU_STATUS_HST_MUL_DONE_MSK+VCORTEX_GPU_STATUS_HST_ACC_DONE_MSK))
	{
		chThdSleepMilliseconds(1);
	}


	IOWR_VCORTEX_GPU_JOB_BFFR_1(job.action);
	IOWR_VCORTEX_GPU_JOB_BFFR_2(job.ptr.x);
	IOWR_VCORTEX_GPU_JOB_BFFR_3(job.ptr.y);
	IOWR_VCORTEX_GPU_JOB_BFFR_4(PACK_HSI_PXL(job.color));
	IOWR_VCORTEX_GPU_JOB_BFFR_0(DEBUG);

	if(wait || (job.action == READ)) {
		while(!(IORD_VCORTEX_GPU_STATUS & VCORTEX_GPU_STATUS_HST_ACC_DONE_MSK)) {
			chThdSleepMilliseconds(1);
		}
	}

	if(job.action == READ) {
		res = IORD_VCORTEX_GPU_JOB_BFFR_4;

		job.color.i = res & 0x7;
		job.color.s = (res >> INTENSITY_W) & 0x3;
		job.color.h = (res >> (SATURATION_W+INTENSITY_W)) & 0x7;
	}

	//alt_printf("[gpu_hst_acc] Done RD/WR:%c ptr.x:0x%x ptr.y0x%x\n",job.action,job.ptr.x,job.ptr.y);


	return job;
}

