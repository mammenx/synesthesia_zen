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
 -- Interface Name    : syn_but_intf
 -- Author            : mammenx
 -- Function          : This interface contains all the signals needed to
                        interact with the butterfly module.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_but_intf  #() (input logic clk_ir,rst_il);

  import  syn_fft_pkg::*;

  //Logic signals
  fft_sample_t    sample_a;
  fft_sample_t    sample_b;
  fft_twdl_t      twdl;
  logic           sample_rdy;
  fft_sample_t    res;
  logic           res_rdy;
  logic           bffr_ovrflw;
  logic           bffr_underflw;


  //Modports
  modport master  (
                    output  sample_a,
                    output  sample_b,
                    output  twdl,
                    output  sample_rdy,

                    input   res,
                    input   res_rdy,

                    input   bffr_ovrflw,
                    input   bffr_underflw
                  );

  modport slave   (
                    input   sample_a,
                    input   sample_b,
                    input   twdl,
                    input   sample_rdy,

                    output  res,
                    output  res_rdy,

                    output  bffr_ovrflw,
                    output  bffr_underflw
                  );

endinterface  //  syn_but_intf
