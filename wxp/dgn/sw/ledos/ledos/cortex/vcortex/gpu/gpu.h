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
 -- Header Name       : gpu.h
 -- Author            : mammenx
 -- Description       : 
 --------------------------------------------------------------------------
*/

#include <io.h>
#include "system.h"


#ifndef GPU_H_
#define GPU_H_

#define	VCORTEX_GPU_BASE_ADDR	0x10000

//Grapheme register addresses
#define VCORTEX_GPU_CONTROL_REG_ADDR      0x10000
#define VCORTEX_GPU_STATUS_REG_ADDR       0x10010
#define VCORTEX_GPU_JOB_BFFR_0_REG_ADDR   0x10020
#define VCORTEX_GPU_JOB_BFFR_1_REG_ADDR   0x10030
#define VCORTEX_GPU_JOB_BFFR_2_REG_ADDR   0x10040
#define VCORTEX_GPU_JOB_BFFR_3_REG_ADDR   0x10050
#define VCORTEX_GPU_JOB_BFFR_4_REG_ADDR   0x10060
#define VCORTEX_GPU_JOB_BFFR_5_REG_ADDR   0x10070
#define VCORTEX_GPU_JOB_BFFR_6_REG_ADDR   0x10080
#define VCORTEX_GPU_JOB_BFFR_7_REG_ADDR   0x10090
#define VCORTEX_GPU_JOB_BFFR_8_REG_ADDR   0x100a0
#define VCORTEX_GPU_JOB_BFFR_9_REG_ADDR   0x100b0

//Field Masks
#define	VCORTEX_GPU_EN_MSK					0x1
#define	VCORTEX_GPU_JOB_ACTION_MSK			0x3
#define	VCORTEX_GPU_STATUS_EUCLID_BUSY_MSK	0x1
#define	VCORTEX_GPU_STATUS_PICASSO_BUSY_MSK	0x2
#define	VCORTEX_GPU_STATUS_HST_ACC_DONE_MSK	0x4
#define	VCORTEX_GPU_STATUS_HST_MUL_DONE_MSK	0x8

//Read GPU Registers
#define	IORD_VCORTEX_GPU_CONTROL			\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_CONTROL_REG_ADDR)

#define	IORD_VCORTEX_GPU_STATUS       \
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_STATUS_REG_ADDR)

#define	IORD_VCORTEX_GPU_JOB_BFFR_0   \
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_0_REG_ADDR)

#define	IORD_VCORTEX_GPU_JOB_BFFR_1   \
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_1_REG_ADDR)

#define	IORD_VCORTEX_GPU_JOB_BFFR_2   \
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_2_REG_ADDR)

#define	IORD_VCORTEX_GPU_JOB_BFFR_3   \
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_3_REG_ADDR)

#define	IORD_VCORTEX_GPU_JOB_BFFR_4   \
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_4_REG_ADDR)

#define	IORD_VCORTEX_GPU_JOB_BFFR_5   \
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_5_REG_ADDR)

#define	IORD_VCORTEX_GPU_JOB_BFFR_6   \
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_6_REG_ADDR)

#define	IORD_VCORTEX_GPU_JOB_BFFR_7   \
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_7_REG_ADDR)

#define	IORD_VCORTEX_GPU_JOB_BFFR_8   \
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_8_REG_ADDR)

#define	IORD_VCORTEX_GPU_JOB_BFFR_9   \
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_9_REG_ADDR)

//Write GPU Registers
#define	IOWR_VCORTEX_GPU_CONTROL(data)			\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_CONTROL_REG_ADDR, data)

#define	IOWR_VCORTEX_GPU_JOB_BFFR_0(data)   \
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_0_REG_ADDR, data)

#define	IOWR_VCORTEX_GPU_JOB_BFFR_1(data)   \
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_1_REG_ADDR, data)

#define	IOWR_VCORTEX_GPU_JOB_BFFR_2(data)   \
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_2_REG_ADDR, data)

#define	IOWR_VCORTEX_GPU_JOB_BFFR_3(data)   \
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_3_REG_ADDR, data)

#define	IOWR_VCORTEX_GPU_JOB_BFFR_4(data)   \
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_4_REG_ADDR, data)

#define	IOWR_VCORTEX_GPU_JOB_BFFR_5(data)   \
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_5_REG_ADDR, data)

#define	IOWR_VCORTEX_GPU_JOB_BFFR_6(data)   \
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_6_REG_ADDR, data)

#define	IOWR_VCORTEX_GPU_JOB_BFFR_7(data)   \
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_7_REG_ADDR, data)

#define	IOWR_VCORTEX_GPU_JOB_BFFR_8(data)   \
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_8_REG_ADDR, data)

#define	IOWR_VCORTEX_GPU_JOB_BFFR_9(data)   \
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_GPU_JOB_BFFR_9_REG_ADDR, data)

#endif /* GPU_H_ */
