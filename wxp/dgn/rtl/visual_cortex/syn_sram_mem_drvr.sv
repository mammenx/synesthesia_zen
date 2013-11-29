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
 -- Module Name       : syn_sram_mem_drvr
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This block contains logic for interfacing to the
                        512KB SRAM memory on the DE1 board.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_sram_mem_drvr (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf           cr_intf,      //Clock Reset Interface

  sram_acc_intf                   sram_bus_intf,

  syn_sram_mem_intf               sram_mem_intf


  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic [15:0]                writedata_reg;


//----------------------- Internal Wire Declarations ----------------------





//----------------------- Start of Code -----------------------------------

  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : seq_logic
   if(~cr_intf.rst_sync_l)
   begin
    sram_bus_intf.sram_rd_data<=  0;
    writedata_reg             <=  0;

    sram_mem_intf.SRAM_ADDR   <=  0;
    sram_mem_intf.SRAM_LB_N   <=  1'b1;
    sram_mem_intf.SRAM_UB_N   <=  1'b1;
    sram_mem_intf.SRAM_CE_N   <=  1'b1;
    sram_mem_intf.SRAM_OE_N   <=  1'b1;
    sram_mem_intf.SRAM_WE_N   <=  1'b1;
   end
   else
   begin
    sram_bus_intf.sram_rd_data  <=  sram_mem_intf.SRAM_OE_N ? sram_bus_intf.sram_rd_data  : sram_mem_intf.SRAM_DQ;
    writedata_reg <= sram_bus_intf.sram_wr_data;

    sram_mem_intf.SRAM_ADDR  <= sram_bus_intf.sram_addr;
    sram_mem_intf.SRAM_LB_N  <= ~(sram_bus_intf.sram_be[0] & sram_bus_intf.sram_cs);
    sram_mem_intf.SRAM_UB_N  <= ~(sram_bus_intf.sram_be[1] & sram_bus_intf.sram_cs);
    sram_mem_intf.SRAM_CE_N  <= ~(sram_bus_intf.sram_cs);
    sram_mem_intf.SRAM_OE_N  <= ~(sram_bus_intf.sram_rd_en  & sram_bus_intf.sram_cs);
    sram_mem_intf.SRAM_WE_N  <= ~(sram_bus_intf.sram_wr_en  & sram_bus_intf.sram_cs);
   end
  end

  //SRAM_DQ Tristate logic
  assign sram_mem_intf.SRAM_DQ  = (~sram_mem_intf.SRAM_WE_N) ? writedata_reg : 16'hzzzz;

endmodule // syn_sram_mem_drvr
