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
 -- Interface Name    : syn_clk_rst_async_intf
 -- Author            : mammenx
 -- Function          : This interface encapsulates a typical clock & its
                        associated asynchronous reset signal.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_clk_rst_async_intf  #(parameter NO_OF_SYNC_STAGES = 2)

                                  (input logic clk_ir,  rst_async_il);

  //Synchronizer flops
  logic [NO_OF_SYNC_STAGES-1:0]   sync_f;

  //Synchronous reset
  logic rst_sync_l;


  /*
    * Synchronizing the async reset signal to clock
    * Assertion of rst_sync_l should be immediate i.e. asynchronous
    * Deassertion of rst_sync_l should be wrt clk_r
  */
  always_ff@(posedge  clk_ir, negedge  rst_async_il)
  begin : RESET_SYNCHRONIZATION
    if(~rst_async_il)
    begin
      sync_f                  <=  '0;
      rst_sync_l              <=  '0;
    end
    else
    begin
      {rst_sync_l,  sync_f}   <=  {sync_f,  1'b1};
    end
  end : RESET_SYNCHRONIZATION


  //Modport
  modport sync  (
                  input clk_ir, rst_sync_l
                );


endinterface  //  syn_clk_rst_async_intf
