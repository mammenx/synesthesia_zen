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
 -- Component Name    : syn_vga_seq_item
 -- Author            : mammenx
 -- Function          : This class describes a typical vga transaction with
                        pixel & timing information.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_VGA_SEQ_ITEM
`define __SYN_VGA_SEQ_ITEM

  import  syn_gpu_pkg::pxl_rgb_t;

  class syn_vga_seq_item  #(parameter type PIXEL_TYPE = pxl_rgb_t
                           ) extends ovm_sequence_item;

    //fields
    rand  PIXEL_TYPE      pxl_arry[];

    //registering with factory
    `ovm_object_param_utils_begin(syn_vga_seq_item#(PIXEL_TYPE))
      `ovm_field_sarray_int(pxl_arry,  OVM_ALL_ON | OVM_HEX);
    `ovm_object_utils_end

    /*  Constructor */
    function new(string name = "syn_vga_seq_item");
      super.new(name);
    endfunction : new


    /*  Constraint  Block */

    /*  Function to check a pkt of same type */
    function  string  check (input  syn_vga_seq_item#(PIXEL_TYPE) item);
      string  res = "";

      if(this.pxl_arry.size !=  item.pxl_arry.size)
      begin
        res = {res,$psprintf("\nMismatch in pxl_arry.size value, expected : [%1d], actual : [%1d]",this.pxl_arry.size,item.pxl_arry.size)};
      end
      else  //to avoid any runtime errors
      begin
        foreach(this.pxl_arry[i])
        begin
          if(this.pxl_arry[i] !=  item.pxl_arry[i])
            res = {res,$psprintf("\nMismatch in pxl_arry[%1d] value, expected : [%1d], actual : [%1d]",i,this.pxl_arry[i],item.pxl_arry[i])};
        end
      end

      return  res;

    endfunction : check


  endclass  : syn_vga_seq_item

`endif
