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
 -- Interface Name    : mem_intf
 -- Author            : mammenx
 -- Function          : This interface contains all the signals needed to
                        read/write data from a RAM block.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface mem_intf  #(
                      parameter RAM_DATA_W  = 32,
                      parameter RAM_ADDR_W  = 7
                    )
                    
                    (input logic clk_ir,  rst_il);

  //Logic signals
  logic [RAM_ADDR_W-1:0]  addr;
  logic [RAM_DATA_W-1:0]  wdata;
  logic                   wren;
  logic [RAM_DATA_W-1:0]  rdata;


  //Modports
  modport master  (
                    output  addr,
                    output  wdata,
                    output  wren,
                    input   rdata
                  );

  modport slave   (
                    input   addr,
                    input   wdata,
                    input   wren,
                    output  rdata
                  );

endinterface  //  mem_intf
