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
 -- Module Name       : syn_gpu_poly_drwr
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : 
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_gpu_poly_drwr (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf.sync  cr_intf,  //Clock Reset Synchronous interface

  syn_lb_intf.slave           lb_intf,  //Local Bus interface

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------


//----------------------- Internal Interface Declarations -----------------


//----------------------- FSM Declarations --------------------------------
enum  logic [?:0] {IDLE_S, ... }  fsm_pstate, next_state;



//----------------------- Start of Code -----------------------------------
//code should be  <=200 lines

//use always_comb to model combinational logic

//use always_ff to model sequential logic

//use always_latch to safely infer combinational latches

//specify names for always,if,case blocks

endmodule // syn_gpu_poly_drwr
