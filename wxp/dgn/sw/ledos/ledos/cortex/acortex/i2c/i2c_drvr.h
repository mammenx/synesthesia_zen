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
 -- File Name         : i2c_drvr.h
 -- Author            : mammenx
 -- Function          : 
 --------------------------------------------------------------------------
*/

#ifndef I2C_DRVR_H_
#define I2C_DRVR_H_

#include <io.h>
#include "system.h"

#define	I2C_DRIVER_BASE_ADDR	0x00000


//I2C_DRIVER REG Addresses
#define I2C_DRIVER_STATUS_REG_ADDR        	0x00000
#define I2C_DRIVER_ADDR_REG_ADDR          	0x00010
#define I2C_DRIVER_DATA_REG_ADDR          	0x00020
#define I2C_DRIVER_CLK_DIV_REG_ADDR       	0x00030

//Field Masks
#define	I2C_DRIVER_STATUS_BUSY_MSK			0x0001
#define	I2C_DRIVER_STATUS_NACK_MSK			0x0002
#define	I2C_DRIVER_ADDR_MSK					0x00ff
#define	I2C_DRIVER_CLK_DIV_MSK				0x00ff


//Read I2C fields
#define	IORD_I2C_STATUS			\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, I2C_DRIVER_STATUS_REG_ADDR)

#define IORD_I2C_ADDR				\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, I2C_DRIVER_ADDR_REG_ADDR)

#define IORD_I2C_DATA				\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, I2C_DRIVER_DATA_REG_ADDR)

#define IORD_I2C_CLK_DIV			\
		IORD_32DIRECT(CORTEX_MM_SLAVE_BASE, I2C_DRIVER_CLK_DIV_REG_ADDR)


//Write I2C fields
#define	IOWR_I2C_STATUS(data)		\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, I2C_DRIVER_STATUS_REG_ADDR, data)

#define IOWR_I2C_ADDR(data)		\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, I2C_DRIVER_ADDR_REG_ADDR, data)

#define IOWR_I2C_DATA(data)		\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, I2C_DRIVER_DATA_REG_ADDR, data)

#define IOWR_I2C_CLK_DIV(data)	\
		IOWR_32DIRECT(CORTEX_MM_SLAVE_BASE, I2C_DRIVER_CLK_DIV_REG_ADDR, data)


//Utils
typedef enum {
	I2C_OK	=	0,		/*	(0)	RD/WR Transaction success	*/
	I2C_NACK_DETECTED,	/*	(1)	Invalid I2C transaction		*/
	I2C_BUSY,			/*	(2)	I2C is busy in a transaction*/
	I2C_IDLE			/*	(3) I2C is ready for new transaction	*/

} I2C_RES;


I2C_RES	get_i2c_status();
I2C_RES	is_busy();
I2C_RES	i2c_xtn_write16(alt_u8 addr, alt_u16 data);
void 	configure_i2c_clk(alt_u8 clk_val);
alt_u8 	get_i2c_clk();

#endif /* I2C_DRVR_H_ */
