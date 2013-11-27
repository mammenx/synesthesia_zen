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
 -- Interface Name    : syn_sram_acc_agent_intf
 -- Author            : mammenx
 -- Function          : This interface has all the signals needed by an agent
                        to interface with the sram access bus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_sram_acc_agent_intf  #(DATA_W=16,ADDR_W=18) (input logic  clk_ir,rst_il,rdy,rd_valid, logic[DATA_W-1:0] rd_data,
                                                           inout logic rd_en,wr_en,  logic[DATA_W-1:0] wr_data,  logic[ADDR_W-1:0] addr);

  clocking  cb@(posedge  clk_ir);
    default input #2ns output #2ns;

    inout   rd_en;
    inout   wr_en;
    inout   addr;
    inout   wr_data;
    input   rdy;
    input   rd_valid;
    input   rd_data;

  endclocking : cb

  //Modports
  modport TB  (clocking cb, input clk_ir, rst_il);


endinterface  //  syn_sram_acc_agent_intf
