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
 -- Interface Name    : syn_pcm_mem_intf
 -- Author            : mammenx
 -- Function          : This interace contains all the signals required to
                        transfer PCM data from Acortex to Fgyrus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_pcm_mem_intf  #(DATA_W=32,ADDR_W=7,RD_DELAY=2) (input logic clk_ir,rst_il);

  //Logic signals
  wire                     pcm_data_rdy;
  wire [ADDR_W-1:0]        pcm_addr;
  wire [DATA_W-1:0]        lpcm_wdata;
  wire [DATA_W-1:0]        rpcm_wdata;
  wire                     pcm_wren;
  wire                     pcm_rden;
  wire [DATA_W-1:0]        lpcm_rdata;
  wire [DATA_W-1:0]        rpcm_rdata;
  wire                     pcm_rd_valid;
  wire [ADDR_W-1:0]        pcm_raddr;

  //Clocking Blocks
  clocking  cb  @(posedge clk_ir);
    default input #2ns  output  #2ns;

    inout   pcm_data_rdy;
    inout   pcm_addr;
    inout   lpcm_wdata;
    inout   rpcm_wdata;
    inout   pcm_wren;
    inout   pcm_rden;
    inout   lpcm_rdata;
    inout   rpcm_rdata;
    inout   pcm_rd_valid;
    input   pcm_raddr;  //to be used only by monitor

  endclocking : cb

  /*  Read address delay logic  */
  logic [(ADDR_W*RD_DELAY)-1:0]  pcm_raddr_del;

  always_ff@(posedge clk_ir, negedge rst_il)
  begin
    if(~rst_il)
    begin
      pcm_raddr_del <=  0;
    end
    else
    begin
      pcm_raddr_del <=  {pcm_raddr_del[(ADDR_W*(RD_DELAY-1))-1:0],pcm_addr};
    end
  end

  assign  pcm_raddr = pcm_raddr_del[(ADDR_W*(RD_DELAY-1)) +:  ADDR_W];


  //Modports
  modport TB  (input   clk_ir,rst_il, clocking  cb);


endinterface  //  syn_pcm_mem_intf
