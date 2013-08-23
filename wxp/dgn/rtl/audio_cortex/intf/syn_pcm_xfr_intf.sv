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
 -- Interface Name    : syn_pcm_xfr_intf
 -- Author            : mammenx
 -- Function          : This interface contains signals required to transfer
                        PCM data.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_pcm_xfr_intf  (input logic  clk_ir,rst_il); 

  import  syn_audio_pkg::pcm_data_t;

  //Logic signals
  logic       pcm_data_valid;
  pcm_data_t  pcm_data;
  logic       ack;


  //Modports
  modport master  (
                    output  pcm_data_valid,
                    output  pcm_data,
                    input   ack
                  );

  modport slave   (
                    input   pcm_data_valid,
                    input   pcm_data,
                    output  ack
                  );


  /*
    * Timing Diagram
    *
    *                      __________________
    * pcm_data_valid      |                  |
    *                 ____|                  |____
    *                 ___  _________________  ____
    * pcm_data        xxx\/  valid pcm data \/xxx
    *                 ___/\_________________/\____
    *                                   ____
    * ack                              |    |
    *                 _________________|    |_____
    *
  */


endinterface  //  syn_pcm_xfr_intf
