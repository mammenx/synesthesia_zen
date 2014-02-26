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
 -- File Name         : acache.c
 -- Author            : mammenx
 -- Function          : 
 --------------------------------------------------------------------------
*/

#include "acache.h"
#include "alt_types.h"
#include "sys/alt_stdio.h"

void update_acache_mode(ACACHE_MODE_T mode){
	IOWR_ACACHE_CTRL(mode & ACACHE_MODE_MSK);
}

void reset_acache(){
	IOWR_ACACHE_HST_RST(0x0);
}

void dump_acache_cap_data(alt_u32* bffr){
	alt_u16 i;

	for(i=0; i<ACACHE_CAP_NO_SAMPLES; i++){
		IOWR_ACACHE_CAP_NO(i & ACACHE_CAP_ADDR_MSK);
		bffr[i] = IORD_ACACHE_CAP_DATA;
	}
}
