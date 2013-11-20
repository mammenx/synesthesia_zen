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
 -- Interface Name    : syn_vga_intf
 -- Author            : mammenx
 -- Function          : This contains all the signals related to the VGA
                        interface in DE1 board.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


interface syn_vga_intf  #(parameter WIDTH = 4) (input logic clk_ir, rst_il);

  //Logic signals
  logic [WIDTH-1:0] r;
  logic [WIDTH-1:0] g;
  logic [WIDTH-1:0] b;
  logic             hsync_n;
  logic             vsync_n;


  //Modports
  modport mp  (
                output  r,
                output  g,
                output  b,
                output  hsync_n,
                output  vsync_n
              );

  modport TB  (
                input   clk_ir,
                input   rst_il,
                input   r,
                input   g,
                input   b,
                input   hsync_n,
                input   vsync_n
              );

endinterface  //  syn_vga_intf
