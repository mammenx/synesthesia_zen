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
 -- File Name         : i2c_drvr.c
 -- Author            : mammenx
 -- Function          : 
 --------------------------------------------------------------------------
*/

#include "i2c_drvr.h"
#include "alt_types.h"
#include "sys/alt_stdio.h"
#include "ch.h"


I2C_RES	get_i2c_status(){
	alt_u32	reg	=	IORD_I2C_STATUS;

	if(reg	&	I2C_DRIVER_STATUS_NACK_MSK){
		return I2C_NACK_DETECTED;
	}
	else if(reg	&	I2C_DRIVER_STATUS_BUSY_MSK){
		return I2C_BUSY;
	}

	return I2C_IDLE;
}


I2C_RES	is_busy(){
	alt_u32	reg	=	IORD_I2C_STATUS;

	if(reg	&	I2C_DRIVER_STATUS_BUSY_MSK){
		return I2C_BUSY;
	}

	return I2C_IDLE;

}


I2C_RES	i2c_xtn_write16(alt_u8 addr, alt_u16 data){

	while(IORD_I2C_STATUS & I2C_DRIVER_STATUS_BUSY_MSK){
		//alt_printf("Waiting for I2C driver to be free\n");
	    chThdSleepMilliseconds(1);	//wait for I2C driver to be free
	}
	//alt_printf("I2C driver is free\n");


	IOWR_I2C_DATA(data);
	IOWR_I2C_ADDR(addr	&	0xfe);	//forcing bit[0] to ground for write op

	IOWR_I2C_STATUS(0x0);	//writing to Status register triggers I2C xtn

	while(IORD_I2C_STATUS & I2C_DRIVER_STATUS_BUSY_MSK){
		//alt_printf("Waiting for I2C driver to be free\n");

		chThdSleepMilliseconds(1);	//wait for I2C driver to be free
	}

	//alt_printf("I2C driver is free\n");
	//alt_printf("I2C status 0x%x\n",IORD_I2C_STATUS(base));


	if(IORD_I2C_STATUS	&	I2C_DRIVER_STATUS_NACK_MSK){

		return I2C_NACK_DETECTED;
	}

	return I2C_OK;
}


void configure_i2c_clk(alt_u8 clk_val){
	IOWR_I2C_CLK_DIV(clk_val);

	return;
}


alt_u8 	get_i2c_clk(){
	return (IORD_I2C_CLK_DIV & I2C_DRIVER_CLK_DIV_MSK);
}
