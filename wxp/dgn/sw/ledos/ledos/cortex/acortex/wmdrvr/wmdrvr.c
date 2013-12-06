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
 -- File Name         : wmdrvr.c
 -- Author            : mammenx
 -- Function          : 
 --------------------------------------------------------------------------
*/

#include "wmdrvr.h"
#include "alt_types.h"
#include "sys/alt_stdio.h"

void disable_dac_drvr(){
	IOWR_WMDRVR_CTRL(IORD_WMDRVR_CTRL & ~WMDRVR_DAC_EN_MSK);
}

void enable_dac_drvr(){
	IOWR_WMDRVR_CTRL((IORD_WMDRVR_CTRL & ~WMDRVR_DAC_EN_MSK) + WMDRVR_DAC_EN_MSK);
}

void disable_adc_drvr(){
	IOWR_WMDRVR_CTRL(IORD_WMDRVR_CTRL & ~WMDRVR_ADC_EN_MSK);
}

void enable_adc_drvr(){
	IOWR_WMDRVR_CTRL((IORD_WMDRVR_CTRL & ~WMDRVR_ADC_EN_MSK) + WMDRVR_ADC_EN_MSK);
}

void configure_wmdrvr_bps(BPS_T val){
	IOWR_WMDRVR_CTRL(val & WMDRVR_BPS_MSK);
}

void update_wmdrvr_fs_div(FS_DIV_T val){
	IOWR_WMDRVR_FS_DIV(val & WMDRVR_FS_DIV_VAL_MSK);
}
