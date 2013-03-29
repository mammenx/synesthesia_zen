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
 -- Interface Name    : syn_lb_intf
 -- Author            : mammenx
 -- Function          : This interface encapsulates the internal local bus
                        signals used to decode read/write transactions
                        from a host master to slave.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


interface syn_lb_intf  #(parameter  DATA_W  = 32,
                         parameter  ADDR_W  = 8
                        );

  //Read-Write signals
  logic                 rd_en;
  logic                 wr_en;
  logic [ADDR_W-1:0]    addr;
  logic                 wr_valid;
  logic [DATA_W-1:0]    wr_data;
  logic                 rd_valid;
  logic [DATA_W-1:0]    rd_data;


  //Modports
  modport master  (
                    output  rd_en,
                    output  wr_en,
                    output  addr,
                    output  wr_data,

                    input   wr_valid,
                    input   rd_valid,
                    input   rd_data
                  );


  modport slave   (
                    input   rd_en,
                    input   wr_en,
                    input   addr,
                    input   wr_data,

                    output  wr_valid,
                    output  rd_valid,
                    output  rd_data
                  );


endinterface  //  syn_lb_intf
