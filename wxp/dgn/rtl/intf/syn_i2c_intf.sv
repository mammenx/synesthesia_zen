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
 -- Interface Name    : syn_i2c_intf
 -- Author            : mammenx
 -- Function          : This interface contains all the signals for I2C
                        protocol.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_i2c_intf  ();

  //Logic signals
  logic   scl;
  logic   sda_o;
  logic   sda_i;
  logic   release_sda;

  //Wire Signals
  wire    sda;


  /*  SDA Tristate Logic  */
  assign  sda = release_sda ? 1'bz  : sda_o;

  /*  Tap SDA line for input  */
  assign  sda_i = sda;


  //Modports
  modport dut (
                output  scl,
                output  sda_o,
                input   sda_i,
                output  release_sda
              );


endinterface  //  syn_i2c_intf
