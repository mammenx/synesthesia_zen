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

  class syn_fft_cache_seq_item extends ovm_sequence_item;

    //fields
    fft_sample_t  sample[];
    int           addr[];

    //registering with factory
    `ovm_object_utils_begin(syn_fft_cache_seq_item)
      `ovm_field_array_int(sample,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_array_int(addr,  OVM_ALL_ON | OVM_HEX);
    `ovm_object_utils_end

    /*  Constructor */
    function new(string name = "syn_fft_cache_seq_item");
      super.new(name);
    endfunction : new


    /*  Constraint  Block */


    /*  Function to check a pkt of same type */
    function  string  check (input  syn_fft_cache_seq_item  item);
      string  res = "";

      if(item.addr.size !=  this.addr.size)
        res = {res,$psprintf("Mismatch in addr.size, expected [%1d] actual [%1d]",this.addr.size,item.addr.size)};

      if(item.sample.size !=  this.sample.size)
        res = {res,$psprintf("Mismatch in sample.size, expected [%1d] actual [%1d]",this.sample.size,item.sample.size)};

      foreach(this.sample[i])
      begin
        if(this.sample[i].re  !=  item.sample[i].re)
          res = {res,$psprintf("Mismatch in sample[%1d].re, expected [0x%x] actual [0x%x]",i,this.sample[i].re,item.sample[i].re)};

        if(this.sample[i].im  !=  item.sample[i].im)
          res = {res,$psprintf("Mismatch in sample[%1d].im, expected [0x%x] actual [0x%x]",i,this.sample[i].im,item.sample[i].im)};
      end

      foreach(this.addr[i])
      begin
        if(this.addr[i] !=  item.addr[i])
          res = {res,$psprintf("Mismatch in addr[%1d], expected [0x%x] actual [0x%x]",i,this.addr[i],item.addr[i])};
      end

      return  res;

    endfunction : check

  endclass  : syn_fft_cache_seq_item

`endif
