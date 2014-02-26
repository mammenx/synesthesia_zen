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
 -- Header Name       : vga.h
 -- Author            : mammenx
 -- Description       :
 --------------------------------------------------------------------------
*/

#include <io.h>
#include "system.h"


#ifndef VGA_H_
#define VGA_H_

#define	VCORTEX_VGA_BASE_ADDR	0x11000

//VGA Register Addresses
#define	VCORTEX_VGA_CONTROL_REG_ADDR	0x11000
#define	VCORTEX_VGA_STATUS_REG_ADDR		0x11010

//Field Masks
#define	VCORTEX_VGA_EN_MSK				0x1
#define	VCORTEX_VGA_MODE_MSK			0x2
#define	VCORTEX_VGA_BFFR_OVRFLW_MSK		0x1
#define	VCORTEX_VGA_BFFR_UNDRFLW_MSK	0x2

//Macros to read registers
#define	IORD_VCORTEX_VGA_CONTROL			\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_VGA_CONTROL_REG_ADDR)

#define	IORD_VCORTEX_VGA_STATUS			\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_VGA_STATUS_REG_ADDR)

//Macros to read registers
#define	IOWR_VCORTEX_VGA_CONTROL(data)			\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, VCORTEX_VGA_CONTROL_REG_ADDR, data)

typedef enum {
	VGA_NORMAL=0,
	VGA_TEST_PATTERN=2 //since its bit 1
}VGA_MODE_T;

void vga_en();
void vga_disable();
void set_vga_mode(VGA_MODE_T mode);

#endif /* VGA_H_ */
