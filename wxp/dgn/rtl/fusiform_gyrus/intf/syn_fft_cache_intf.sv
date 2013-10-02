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
 -- Interface Name    : syn_fft_cache_intf
 -- Author            : mammenx
 -- Function          : This interface describes all the signals required
                        to communicate with the FFT Cache block.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_fft_cache_intf  #(parameter DATA_W=32,ADDR_W=8) (input logic  clk_ir,rst_il);

  import  syn_fft_pkg::*;

  /*  First Half is LCHANNEL, second half is RCHANNEL */

  //Logic signals
  fft_sample_t        wr_sample;
  logic               wr_en;
  logic [ADDR_W-1:0]  waddr;
  logic [ADDR_W-1:0]  raddr;
  fft_sample_t        rd_sample;
  logic               rd_en;
  logic               rd_valid;
  logic               fft_done;

  logic [DATA_W-1:0]  hst_wr_data;
  logic               hst_wr_en;
  logic [ADDR_W-1:0]  hst_addr;
  logic               hst_rd_en;
  logic [DATA_W-1:0]  hst_rd_data;
  logic               hst_rd_valid;

  //Wire Signals


  //Tasks & Functions


  //Modports
  modport master  (
                    output  wr_sample,
                    output  wr_en,
                    output  waddr,
                    output  raddr,
                    output  rd_en,
                    input   rd_valid,
                    input   rd_sample,
                    output  fft_done,

                    output  hst_wr_data,
                    output  hst_wr_en,
                    output  hst_addr,
                    output  hst_rd_en,
                    input   hst_rd_data,
                    input   hst_rd_valid
                  );

  modport slave   (
                    input   wr_sample,
                    input   wr_en,
                    input   waddr,
                    input   raddr,
                    input   rd_en,
                    output  rd_valid,
                    output  rd_sample,
                    input   fft_done,

                    input   hst_wr_data,
                    input   hst_wr_en,
                    input   hst_addr,
                    input   hst_rd_en,
                    output  hst_rd_data,
                    output  hst_rd_valid
                  );

endinterface  //  syn_fft_cache_intf
