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
 -- File Name         : wmdrvr.h
 -- Author            : mammenx
 -- Function          : 
 --------------------------------------------------------------------------
*/

#ifndef WMDRVR_H_
#define WMDRVR_H_

#include <io.h>
#include "system.h"

#define	WMDRVR_BASE_ADDR	0x02000

//DAC Driver register addresses
#define WMDRVR_CTRL_REG_ADDR          0x02000
#define WMDRVR_STATUS_REG_ADDR        0x02010
#define WMDRVR_FS_DIV_REG_ADDR        0x02020

//DAC Driver field masks
#define	WMDRVR_DAC_EN_MSK				0x1
#define	WMDRVR_ADC_EN_MSK				0x2
#define	WMDRVR_BPS_MSK					0x4
#define	WMDRVR_IDLE_MSK					0x1
#define	WMDRVR_FS_DIV_VAL_MSK			0x7ff

//Read DAC Driver registers
#define	IORD_WMDRVR_CTRL				\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, WMDRVR_CTRL_REG_ADDR)

#define	IORD_WMDRVR_STATUS				\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, WMDRVR_STATUS_REG_ADDR)

#define	IORD_WMDRVR_FS_DIV				\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, WMDRVR_FS_DIV_REG_ADDR)

//Write DAC Driver registers
#define	IOWR_WMDRVR_CTRL(data)				\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, WMDRVR_CTRL_REG_ADDR, data)

#define	IOWR_WMDRVR_FS_DIV(data)				\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, WMDRVR_FS_DIV_REG_ADDR, data)


typedef	enum	{	//	==	BCLK_FREQ(6.25MHz)	/	FS
	FS_DIV_8KHZ		=	781,
	FS_DIV_32KHZ	=	195,
	FS_DIV_44KHZ	=	142,
	FS_DIV_48KHZ	=	130,
	FS_DIV_88KHZ	=	71,
	FS_DIV_96KHZ	=	65
}FS_DIV_T;

typedef	enum	{
	BPS_32	=	1,
	BPS_16	=	0
}BPS_T;


//Utils
void disable_dac_drvr();
void enable_dac_drvr();
void disable_adc_drvr();
void enable_adc_drvr();
void configure_wmdrvr_bps(BPS_T val);
void update_wmdrvr_fs_div(FS_DIV_T val);


#endif /* WMDRVR_H_ */
