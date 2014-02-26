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
 -- File Name         : acache.h
 -- Author            : mammenx
 -- Function          : 
 --------------------------------------------------------------------------
*/

#ifndef ACACHE_H_
#define ACACHE_H_

#include <io.h>
#include "system.h"
#include "alt_types.h"


#define	ACACHE_BASE_ADDR	0x03000

//ACACHE register addresses
#define	ACACHE_CNTRL_REG_ADDR		0x03000
#define	ACACHE_STATUS_REG_ADDR		0x03010
#define	ACACHE_CAP_NO_REG_ADDR		0x03020
#define	ACACHE_CAP_DATA_REG_ADDR	0x03030
#define	ACACHE_HST_RST_REG_ADDR		0x03040

//ACACHE Field masks
#define	ACACHE_MODE_MSK			0x1
#define	ACACHE_CAP_DONE_MSK		0x1
#define	ACACHE_CAP_ADDR_MSK		0xff
#define	ACACHE_CAP_DATA_MSK		0xffffffff

#define ACACHE_CAP_NO_SAMPLES	256

//Read Acache registers
#define	IORD_ACACHE_CTRL				\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, ACACHE_CNTRL_REG_ADDR)

#define	IORD_ACACHE_STATUS				\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, ACACHE_STATUS_REG_ADDR)

#define	IORD_ACACHE_CAP_NO				\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, ACACHE_CAP_NO_REG_ADDR)

#define	IORD_ACACHE_CAP_DATA				\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, ACACHE_CAP_DATA_REG_ADDR)

//Write Acache registers
#define	IOWR_ACACHE_CTRL(data)				\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, ACACHE_CNTRL_REG_ADDR, data)

#define	IOWR_ACACHE_CAP_NO(data)				\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, ACACHE_CAP_NO_REG_ADDR, data)

#define	IOWR_ACACHE_HST_RST(data)				\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, ACACHE_HST_RST_REG_ADDR, data)

typedef enum{
	ACACHE_NORMAL  = 0,
	ACACHE_CAPTURE = 1
}ACACHE_MODE_T;

void update_acache_mode(ACACHE_MODE_T mode);
void reset_acache();
void dump_acache_cap_data(alt_u32* bffr);

#endif /* ACACHE_H_ */
