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
 -- File Name         : fgyrus.h
 -- Author            : mammenx
 -- Function          : 
 --------------------------------------------------------------------------
*/

#ifndef FGYRUS_H_
#define FGYRUS_H_

#include <io.h>
#include "system.h"
#include "alt_types.h"


#define	FGYRUS_REG_BASE			0x0000
#define	FGYRUS_FFT_CACHE_BASE	0x1000
#define	FGYRUS_TWDL_RAM_BASE	0x2000
#define	FGYRUS_CORDIC_RAM_BASE	0x3000
#define	FGYRUS_WIN_RAM_BASE		0x4000

//Size (no of locs) of Fgyrus Tables
#define	FGYRUS_FFT_CACHE_SIZE	256
#define	FGYRUS_TWDL_RAM_SIZE	128
#define	FGYRUS_CORDIC_RAM_SIZE	256
#define	FGYRUS_WIN_RAM_SIZE		128

//Fgyrus register addresses
#define	FGYRUS_CTRL_REG_ADDR		0x0000
#define	FGYRUS_STATUS_REG_ADDR		0x0010
#define	FGYRUS_POST_NORM_REG_ADDR	0x0020

//Field Masks
#define	FGYRUS_EN_MSK			0x1
#define	FGYRUS_MODE_MSK			0x2
#define	FGYRUS_BUSY_MSK			0x1
#define	FGYRUS_BUT_UFLW_MSK		0x2
#define	FGYRUS_BUT_OFLW_MSK		0x4
#define	FGYRUS_POST_NORM_MSK	0xf

//Read Fgyrus fields
#define	IORD_FGYRUS_CTRL			\
		IORD_32DIRECT(FFT_CACHE_MM_SLAVE_BASE, FGYRUS_CTRL_REG_ADDR)

#define	IORD_FGYRUS_STATUS			\
		IORD_32DIRECT(FFT_CACHE_MM_SLAVE_BASE, FGYRUS_STATUS_REG_ADDR)

#define	IORD_FGYRUS_POST_NORM			\
		IORD_32DIRECT(FFT_CACHE_MM_SLAVE_BASE, FGYRUS_POST_NORM_REG_ADDR)

//Write Fgyrus fields
#define	IOWR_FGYRUS_CTRL(data)		\
		IOWR_32DIRECT(FFT_CACHE_MM_SLAVE_BASE, FGYRUS_CTRL_REG_ADDR, data)

#define	IOWR_FGYRUS_POST_NORM(data)		\
		IOWR_32DIRECT(FFT_CACHE_MM_SLAVE_BASE, FGYRUS_POST_NORM_REG_ADDR, data)

typedef enum{
	FGYRUS_NORMAL	=	0,
	FGYRUS_CONFIG	=	2	//since its bit[1]
}FGYRUS_MODE_T;

typedef enum{
	FGYRUS_IDLE		=	0,
	FGYRUS_BUSY		=	1,
	FGYRUS_BUT_UFLW	=	2,
	FGYRUS_BUT_OFLW	=	3
}FGYRUS_STATUS_T;

void disable_fgyrus();
void enable_fgyrus();
void update_fgyrus_mode(FGYRUS_MODE_T mode);
FGYRUS_MODE_T get_fgyrus_mode();
FGYRUS_STATUS_T get_fgyrus_status();

void dump_fgyrus_win_ram(alt_u32* bffr);
void dump_fgyrus_twdl_ram(alt_u32* bffr);
void dump_fgyrus_cordic_ram(alt_u16* bffr);
void dump_fgyrus_fft_cache(alt_u32* lbffr, alt_u32*rbffr, alt_u8 num);

void configure_fgyrus_win_ram(alt_u32* bffr);
void configure_fgyrus_twdl_ram(alt_u32* bffr);
void configure_fgyrus_cordic_ram(alt_u16* bffr);
void configure_fgyrus_fft_cache(alt_u32* bffr);


#endif /* FGYRUS_H_ */
