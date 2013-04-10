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
 -- Interface Name    : syn_vga_drvr_lb_intf
 -- Author            : mammenx
 -- Function          : 
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_vga_drvr_lb_intf  (input logic clk_ir, rst_il);

  //Logic signals
  logic   vga_drvr_en;
  logic   bffr_overflow;
  logic   bffr_underflow;


  //Modports
  modport line_bffr (
                      input   vga_drvr_en,
                      output  bffr_overflow,
                      output  bffr_underflow
                    );

  modport fsm       (
                      input   vga_drvr_en
                    );

  modport lb        (
                      output  vga_drvr_en,
                      input   bffr_overflow,
                      input   bffr_underflow
                    );


endinterface  //  syn_vga_drvr_lb_intf
