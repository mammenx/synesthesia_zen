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
 -- Module Name       : <module_name>
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


module <module_name> (

                );

//----------------------- Global parameters Declarations ------------------


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------


//----------------------- FSM Parameters --------------------------------------
//only for FSM state vector representation
parameter     [?:0]                  // synopsys enum fsm_pstate
IDLE               = ,

//----------------------- FSM Register Declarations ------------------
reg           [?:0]                            // synopsys enum fsm_pstate
fsm_pstate, next_state;

//----------------------- FSM String Declarations ------------------
//synthesis translate_off
reg           [8*?:0]      state_name;//"state name" is user defined
//synthesis translate_on

//----------------------- FSM Debugging Logic Declarations ------------------
//synthesis translate_off
always @ (fsm_pstate)
begin
case (fsm_pstate)

<IDLE>       : state_name = "IDLE";

<state2>     : state_name = "state2";
.
.
.
<default>    : state_name = "default";
endcase
end
//synthesis translate_on

//----------------------- Input/Output Registers --------------------------

//----------------------- Start of Code -----------------------------------
//code should be  <=200 lines

/* comments for assign statements 
*/

//assign statements

/* comments for combinatory logic 
   Asynchronous part of FSM
*/


/* comments for sequential logic 
*/
//<sequential logic>;

endmodule // <module_name>
                                                                            
