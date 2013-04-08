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
 -- Interface Name    : ff_intf
 -- Author            : mammenx
 -- Function          : This interface encapsulates generic FIFO signals.
                        The FIFO data type is also parameterized.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


interface ff_intf  #(parameter  DATA_W  = 8);

  //Logic signals
  logic               ff_full;
  logic               ff_empty;
  logic               ff_wr_en;
  logic [DATA_W-1:0]  ff_wr_data;
  logic               ff_rd_en;
  logic [DATA_W-1:0]  ff_rd_data;

  //Modports
  modport rd_only (
                    input   ff_empty,
                    output  ff_rd_en,
                    input   ff_rd_data
                  );

  modport rd_only_slave (
                          output  ff_empty,
                          input   ff_rd_en,
                          output  ff_rd_data
                        );



  modport wr_only (
                    input   ff_full,
                    output  ff_wr_en,
                    output  ff_wr_data
                  );


  modport full    (
                    input   ff_empty,
                    output  ff_rd_en,
                    input   ff_rd_data,

                    input   ff_full,
                    output  ff_wr_en,
                    output  ff_wr_data
                  );

  modport ff_slave  (
                      output  ff_full,
                      output  ff_empty,
                      input   ff_wr_en,
                      input   ff_wr_data,
                      input   ff_rd_en,
                      output  ff_rd_data
                    );

endinterface  //  ff_intf
