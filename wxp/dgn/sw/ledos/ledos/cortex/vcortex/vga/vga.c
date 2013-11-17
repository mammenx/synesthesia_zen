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
 -- File Name         : vga.c
 -- Author            : mammenx
 -- Description       :
 --------------------------------------------------------------------------
*/

#include "vga.h"

void vga_en() {
	IOWR_VCORTEX_VGA_CONTROL(IORD_VCORTEX_VGA_CONTROL | VCORTEX_VGA_EN_MSK);
	return;
}

void vga_disable() {
	IOWR_VCORTEX_VGA_CONTROL(IORD_VCORTEX_VGA_CONTROL & ~VCORTEX_VGA_EN_MSK);
	return;
}

void set_vga_mode(VGA_MODE_T mode){
	IOWR_VCORTEX_VGA_CONTROL(IORD_VCORTEX_VGA_CONTROL & ~VCORTEX_VGA_MODE_MSK);
	IOWR_VCORTEX_VGA_CONTROL(IORD_VCORTEX_VGA_CONTROL | (mode & VCORTEX_VGA_MODE_MSK));
	return;
}
