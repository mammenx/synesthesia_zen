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
 -- Interface Name    : syn_anti_alias_status_intf
 -- Author            : mammenx
 -- Function          : This interfaces contains status signals related to
                        the anti-alias module that need to pulled out for
                        LB access.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_anti_alias_status_intf  (input logic clk_ir,rst_il);

  //Logic signals
  logic   job_que_empty;


  //Wire Signals


  //Modports
  modport anti_alias_mp (
                          output  job_que_empty
                        );

  modport lb_mp (
                  input job_que_empty
                );


endinterface  //  syn_anti_alias_status_intf
