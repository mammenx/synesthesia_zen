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
 -- Component Name    : syn_pcm_seq_item
 -- Author            : mammenx
 -- Function          : This class describes a typical pcm transaction
                        item.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_PCM_SEQ_ITEM
`define __SYN_PCM_SEQ_ITEM

  import  syn_audio_pkg::*;
  import  syn_math_pkg::*;

  class syn_pcm_seq_item extends ovm_sequence_item;

    //fields
    rand  pcm_data_t  pcm_data[];

    //registering with factory
    `ovm_object_utils_begin(syn_pcm_seq_item)
      `ovm_field_array_int(pcm_data,  OVM_ALL_ON | OVM_HEX);
    `ovm_object_utils_end

    /*  Constructor */
    function new(string name = "syn_pcm_seq_item");
      super.new(name);
    endfunction : new


    /*  Constraint  Block */


    /*  Function to check a pkt of same type */
    function  string  check (input  syn_pcm_seq_item item);
      string  res = "";

      if(this.pcm_data.size !=  item.pcm_data.size)
        res = {res,$psprintf("Mismatch in pcm_data.size, expected [%1d] actual [%1d]",this.pcm_data.size,item.pcm_data.size)};

      foreach(this.pcm_data[i])
      begin
        if(this.pcm_data[i].lchnnl  !=  item.pcm_data[i].lchnnl)
          res = {res,$psprintf("Mismatch in pcm_data[%1d].lchnnl, expected [0x%x] actual [0x%x]",i,this.pcm_data[i].lchnnl,item.pcm_data[i].lchnnl)};

        if(this.pcm_data[i].rchnnl  !=  item.pcm_data[i].rchnnl)
          res = {res,$psprintf("Mismatch in pcm_data[%1d].rchnnl, expected [0x%x] actual [0x%x]",i,this.pcm_data[i].rchnnl,item.pcm_data[i].rchnnl)};
      end

      return  res;

    endfunction : check

    /*  Function to fill self with Sine/Cosine values */
    function  void  fill_sin(int num_samples,  int freq, int mag,  int fs=44100);

      this.pcm_data = new[num_samples];

      foreach(this.pcm_data[n])
      begin
        $cast(pcm_data[n].lchnnl,  mag*syn_sin((2*pi*freq*n)/fs));
        $cast(pcm_data[n].rchnnl,  mag*syn_sin((2*pi*freq*n)/fs));
      end

    endfunction : fill_sin

    /*  Function to fill self with incremental pattern  */
    function  void  fill_inc(int num_samples, int start=0, int step=1);
      this.pcm_data = new[num_samples];

      foreach(this.pcm_data[n])
      begin
        $cast(pcm_data[n].lchnnl, start + (n*step));
        $cast(pcm_data[n].rchnnl, start + (n*step) + num_samples);
      end

    endfunction : fill_inc

  endclass  : syn_pcm_seq_item

`endif
