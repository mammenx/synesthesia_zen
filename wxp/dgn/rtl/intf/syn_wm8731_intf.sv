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
 -- Interface Name    : syn_wm8731_intf
 -- Author            : mammenx
 -- Function          : This interface contains all the signals required to
                        interface with the WM8731 Audio Codec.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_wm8731_intf  ();

  //Logic signals
  logic   mclk;

  logic   bclk;
  logic   adc_dat;
  logic   adc_lrc;
  logic   dac_dat;
  logic   dac_lrc;

  //Interfaces
  syn_i2c_intf  i2c_intf();


  //Modports
  modport i2c     (
                    output  i2c_intf.scl,
                    output  i2c_intf.sda_o,
                    input   i2c_intf.sda_i,
                    output  i2c_intf.release_sda
                  );

  modport cmux    (
                    output  mclk
                  );

  modport wmdrvr  (
                    output  bclk,
                    input   adc_dat,
                    output  adc_lrc,
                    output  dac_dat,
                    output  dac_lrc
                  );


endinterface  //  syn_wm8731_intf
