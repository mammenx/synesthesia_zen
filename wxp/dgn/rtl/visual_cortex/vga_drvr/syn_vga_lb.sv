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
 -- Module Name       : syn_vga_lb
 -- Author            : mammenx
 -- Associated modules: 
 -- Function          : This module decodes the LB transactions for VGA
                        block & maintains the control status registers.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`timescale 1ns / 10ps


module syn_vga_lb (

  //--------------------- Interfaces --------------------
  syn_clk_rst_sync_intf       cr_intf,      //Clock Reset Interface

  syn_lb_intf                 lb_intf,      //DATA_W=32,  ADDR_W=8

  syn_vga_drvr_lb_intf        vga_lb_intf   //Interface to local signals

  //--------------------- Misc Ports (Logic)  -----------

                );

//----------------------- Global parameters Declarations ------------------
  import  syn_global_pkg::*;
  `include  "syn_vcortex_reg_map.sv"


//----------------------- Input Declarations ------------------------------


//----------------------- Inout Declarations ------------------------------


//----------------------- Output Declarations -----------------------------


//----------------------- Output Register Declaration ---------------------


//----------------------- Internal Register Declarations ------------------
  logic                       vga_drvr_en_f;
  logic                       bffr_overflow_f;
  logic                       bffr_underflow_f;

//----------------------- Internal Wire Declarations ----------------------






//----------------------- Start of Code -----------------------------------

  /*  LB Decoding logic */
  always_ff@(posedge cr_intf.clk_ir, negedge cr_intf.rst_sync_l)
  begin : lb_decoding_logic
    if(~cr_intf.rst_sync_l)
    begin
      vga_drvr_en_f           <=  0;
      bffr_overflow_f         <=  0;
      bffr_underflow_f        <=  0;

      lb_intf.wr_valid        <=  0;
      lb_intf.rd_valid        <=  0;
      lb_intf.rd_data         <=  0;
    end
    else
    begin
      if(lb_intf.wr_en)
      begin
        unique  case(lb_intf.addr)

          VCORTEX_VGA_CONTROL_REG_ADDR  :
          begin
            vga_drvr_en_f     <=  lb_intf.wr_data[0];
          end

        endcase
      end

      lb_intf.wr_valid        <=  lb_intf.wr_en;

      //Sticky, clear on read logic
      if(bffr_overflow_f)
      begin
        bffr_overflow_f       <=  (lb_intf.addr ==  VCORTEX_VGA_STATUS_REG_ADDR)  ? ~lb_intf.rd_en  : bffr_overflow_f;
      end
      else
      begin
        bffr_overflow_f       <=  vga_lb_intf.bffr_overflow;
      end

      if(bffr_underflow_f)
      begin
        bffr_underflow_f      <=  (lb_intf.addr ==  VCORTEX_VGA_STATUS_REG_ADDR)  ? ~lb_intf.rd_en  : bffr_underflow_f;
      end
      else
      begin
        bffr_underflow_f      <=  vga_lb_intf.bffr_underflow;
      end

      if(lb_intf.rd_en)
      begin
        case(lb_intf.addr)

          VCORTEX_VGA_CONTROL_REG_ADDR  : lb_intf.rd_data <=  {{P_32B_W-1{1'd0}}, vga_drvr_en_f};

          VCORTEX_VGA_STATUS_REG_ADDR   : lb_intf.rd_data <=  {{P_32B_W-2{1'd0}}, bffr_underflow_f, bffr_overflow_f};

          default : lb_intf.rd_data <=  32'hdeadbabe;

        endcase
      end

      lb_intf.rd_valid        <=  lb_intf.rd_en;
    end
  end

  assign  vga_lb_intf.vga_drvr_en = vga_drvr_en_f;

endmodule // syn_vga_lb
