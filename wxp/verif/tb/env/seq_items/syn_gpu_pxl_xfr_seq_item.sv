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
 -- Component Name    : syn_gpu_pxl_xfr_seq_item
 -- Author            : mammenx
 -- Function          : This class describes a typical transaction with
                        pixel information.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_GPU_PXL_XFR_SEQ_ITEM
`define __SYN_GPU_PXL_XFR_SEQ_ITEM

  import  syn_gpu_pkg::pxl_hsi_t;

  typedef enum  {PXL_READ=0, PXL_WRITE=1}  pxl_xfr_xtn_t;

  class syn_gpu_pxl_xfr_seq_item  #(parameter type PIXEL_TYPE = pxl_hsi_t
                                  ) extends ovm_sequence_item;

    //fields
    rand  PIXEL_TYPE      pxl;
    rand  int             posx;
    rand  int             posy;
    rand  pxl_xfr_xtn_t   xtn;

    //registering with factory
    `ovm_object_param_utils_begin(syn_gpu_pxl_xfr_seq_item#(PIXEL_TYPE))
      `ovm_field_int(pxl,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_int(posx,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_int(posy,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_enum(pxl_xfr_xtn_t, xtn,  OVM_ALL_ON  | OVM_ENUM);
    `ovm_object_utils_end

    /*  Constructor */
    function new(string name = "syn_gpu_pxl_xfr_seq_item");
      super.new(name);
    endfunction : new


    /*  Constraint  Block */

    /*  Function to check a pkt of same type */
    function  string  check (input  syn_gpu_pxl_xfr_seq_item#(PIXEL_TYPE) item);
      string  res = "";

      if(this.pxl !=  item.pxl) res = {res,$psprintf("\nMismatch in pxl value, expected : [%1d %1d %1d], actual : [%1d %1d %1d]",
                                                      this.pxl.h,this.pxl.s,this.pxl.i,item.pxl.h,item.pxl.s,item.pxl.i
                                                    )
                                      };

      if(this.posx  !=  item.posx)  res = {res,$psprintf("\nMismatch in posx value, expected : [%1d], actual : [%1d]",this.posx,item.posx)};

      if(this.posy  !=  item.posy)  res = {res,$psprintf("\nMismatch in posy value, expected : [%1d], actual : [%1d]",this.posy,item.posy)};

      if(this.xtn   !=  item.xtn)   res = {res,$psprintf("\nMismatch in xtn value, expected : [%s], actual : [%s]",this.xtn.name,item.xtn.name)};

      return  res;

    endfunction : check


  endclass  : syn_gpu_pxl_xfr_seq_item

`endif
