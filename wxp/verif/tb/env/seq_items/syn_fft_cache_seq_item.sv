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
 -- Component Name    : syn_fft_cache_seq_item
 -- Author            : mammenx
 -- Function          : This class describes an FFT cache seq item.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_FFT_CACHE_SEQ_ITEM
`define __SYN_FFT_CACHE_SEQ_ITEM

  import  syn_fft_pkg::*;
  import  syn_math_pkg::*;

  class syn_fft_cache_seq_item extends ovm_sequence_item;

    //fields
    fft_sample_t  sample;
    int           addr;

    //registering with factory
    `ovm_object_utils_begin(syn_fft_cache_seq_item)
      `ovm_field_int(sample.re,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_int(sample.im,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_int(addr,  OVM_ALL_ON | OVM_HEX);
    `ovm_object_utils_end

    /*  Constructor */
    function new(string name = "syn_fft_cache_seq_item");
      super.new(name);
    endfunction : new


    /*  Constraint  Block */


    /*  Function to check a pkt of same type */
    function  string  check (input  syn_fft_cache_seq_item  item, int dev=0);
      string  res = "";
      int exp_re,exp_im,act_re,act_im,this_dev;

      $cast(exp_re, this.sample.re);
      $cast(exp_im, this.sample.im);
      $cast(act_re, item.sample.re);
      $cast(act_im, item.sample.im);


      if(this.addr !=  item.addr)
        res = {res,$psprintf("\nMismatch in addr, expected [0x%x] actual [0x%x]",this.addr,item.addr)};

      this_dev  = syn_abs(exp_re - act_re);

      if(this_dev > dev)
        res = {res,$psprintf("\nMismatch in sample.re, expected [0x%x][%1d] actual [0x%x][%1d] dev:%1d",this.sample.re,exp_re,item.sample.re,act_re,this_dev)};


      this_dev  = syn_abs(exp_im - act_im);

      if(this_dev > dev)
        res = {res,$psprintf("\nMismatch in sample.im, expected [0x%x][%1d] actual [0x%x][%1d] dev:%1d",this.sample.im,exp_im,item.sample.im,act_im,this_dev)};


      return  res;

    endfunction : check

  endclass  : syn_fft_cache_seq_item

`endif
