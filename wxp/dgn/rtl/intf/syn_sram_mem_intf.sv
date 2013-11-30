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
 -- Interface Name    : syn_sram_mem_intf
 -- Author            : mammenx
 -- Function          : This contains all the signals related to the
                        IS61LV25616 512KB memory on the DE1 board.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_sram_mem_intf (input  logic clk_ir, rst_il);

  //Logic signals
  logic [17:0]  SRAM_ADDR;  // SRAM Address bus 18 Bits
  logic         SRAM_LB_N;  // SRAM Low-byte Data Mask 
  logic         SRAM_UB_N;  // SRAM High-byte Data Mask 
  logic         SRAM_CE_N;  // SRAM Chip chipselect
  logic         SRAM_OE_N;  // SRAM Output chipselect
  logic         SRAM_WE_N;  // SRAM Write chipselect

  logic [15:0]  SRAM_DO;
  logic [15:0]  SRAM_DI;

  //Wire Signals

  //Modports
  modport mp  (
                output  SRAM_ADDR,
                output  SRAM_LB_N,
                output  SRAM_UB_N,
                output  SRAM_CE_N,
                output  SRAM_OE_N,
                output  SRAM_WE_N,

                output  SRAM_DO,
                input   SRAM_DI

              );

  `ifdef  SIMULATION

  /*  Verif */
  modport TB  (
                input   SRAM_ADDR,
                input   SRAM_LB_N,
                input   SRAM_UB_N,
                input   SRAM_CE_N,
                input   SRAM_OE_N,
                input   SRAM_WE_N,

                input   SRAM_DO,
                output  SRAM_DI

                input   clk_ir,
                input   rst_il

              );
    `endif

endinterface  //  syn_sram_mem_intf
