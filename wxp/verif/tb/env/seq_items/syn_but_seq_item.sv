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
 -- Component Name    : syn_but_seq_item
 -- Author            : mammenx
 -- Function          : This class describes an Butterfly seq item.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_BUT_SEQ_ITEM
`define __SYN_BUT_SEQ_ITEM

  import  syn_fft_pkg::*;
  import  syn_math_pkg::*;

  class syn_but_seq_item extends ovm_sequence_item;

    //fields
    fft_sample_t  sample_a;
    fft_sample_t  sample_b;
    fft_twdl_t    twdl;

    //registering with factory
    `ovm_object_utils_begin(syn_but_seq_item)
      `ovm_field_int(sample_a.re,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_int(sample_a.im,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_int(sample_b.re,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_int(sample_b.im,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_int(twdl.re,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_int(twdl.im,  OVM_ALL_ON | OVM_HEX);
    `ovm_object_utils_end

    /*  Constructor */
    function new(string name = "syn_but_seq_item");
      super.new(name);
    endfunction : new


    /*  Constraint  Block */


    /*  Function to check a pkt of same type */
    function  string  check (input  syn_but_seq_item  item, int dev);
      string  res = "";

      if(syn_abs(this.sample_a.re - item.sample_a.re)  >  dev)
        res = {res,$psprintf("Mismatch in sample_a.re, expected [0x%x] actual [0x%x]",this.sample_a.re,item.sample_a.re)};

      if(syn_abs(this.sample_a.im - item.sample_a.im)  >  dev)
        res = {res,$psprintf("Mismatch in sample_a.im, expected [0x%x] actual [0x%x]",this.sample_a.im,item.sample_a.im)};

      if(syn_abs(this.sample_b.re - item.sample_b.re)  >  dev)
        res = {res,$psprintf("Mismatch in sample_b.re, expected [0x%x] actual [0x%x]",this.sample_b.re,item.sample_b.re)};

      if(syn_abs(this.sample_b.im - item.sample_b.im)  >  dev)
        res = {res,$psprintf("Mismatch in sample_b.im, expected [0x%x] actual [0x%x]",this.sample_b.im,item.sample_b.im)};

      if(syn_abs(this.twdl.re - item.twdl.re)  >  dev)
        res = {res,$psprintf("Mismatch in twdl.re, expected [0x%x] actual [0x%x]",this.twdl.re,item.twdl.re)};

      if(syn_abs(this.twdl.im - item.twdl.im)  >  dev)
        res = {res,$psprintf("Mismatch in twdl.im, expected [0x%x] actual [0x%x]",this.twdl.im,item.twdl.im)};

      return  res;

    endfunction : check

  endclass  : syn_but_seq_item

`endif
