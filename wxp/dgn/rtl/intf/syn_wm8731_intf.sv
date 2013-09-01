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

interface syn_wm8731_intf  (input logic rst_il);

  //Logic signals
  logic   mclk;

  logic   bclk;
  logic   adc_dat;
  logic   adc_lrc;
  logic   dac_dat;
  logic   dac_lrc;

  logic   scl;
  wire    sda;

  //Modports
  modport i2c     (
                    output  scl,
                    inout   sda
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

  `ifdef  SIMULATION
    logic sda_o;
    logic sda_tb_en;

    modport TB_I2C  (
                      input   rst_il,
                      input   scl,
                      inout   sda,
                      output  sda_o,
                      output  sda_tb_en
                    );

    assign  sda = sda_tb_en ? sda_o : 'bz;

    modport TB_DAC  (
                      input   rst_il,
                      input   bclk,
                      input   dac_dat,
                      input   dac_lrc
                    );

    modport TB_ADC  (
                      input   rst_il,
                      input   bclk,
                      output  adc_dat,
                      input   adc_lrc
                    );

  `endif


endinterface  //  syn_wm8731_intf
