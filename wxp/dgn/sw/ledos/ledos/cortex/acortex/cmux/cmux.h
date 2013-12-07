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
 -- File Name         : cmux.h
 -- Author            : mammenx
 -- Function          : 
 --------------------------------------------------------------------------
*/

#ifndef CMUX_H_
#define CMUX_H_

#include <io.h>
#include "system.h"

#define CMUX_BASE_ADDR	0x01000

//CMUX Register addresses
#define	CMUX_CLK_SEL_ADDR	0x01000

//Field Masks
#define	CMUX_CLK_SEL_MSK	0x3
#define	CMUX_CLK_EN_MSK		0x80000000

//Read CMUX fields
#define	IORD_CMUX_CLK_SEL			\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, CMUX_CLK_SEL_ADDR)

//Write CMUX fields
#define	IOWR_CMUX_CLK_SEL(data)		\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, CMUX_CLK_SEL_ADDR, data)

typedef enum {
	MCLK_18	=	0,	//18MHz
	MCLK_12	=	1,	//12MHz
	MCLK_11	=	2,	//11MHz
} CMUX_CLK_T;

void configure_cmux_clk(CMUX_CLK_T clk);
CMUX_CLK_T read_cmux_clk();

#endif /* CMUX_H_ */
