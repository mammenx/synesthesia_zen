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
    function  string  check (input  syn_pcm_seq_item item,  real  dev=0.0);
      string  res = "";
      int     data_min,data_max,data;

      if(this.pcm_data.size !=  item.pcm_data.size)
        res = {res,$psprintf("\nMismatch in pcm_data.size, expected [%1d] actual [%1d]",this.pcm_data.size,item.pcm_data.size)};

      foreach(this.pcm_data[i])
      begin
        $cast(data_min, (1.0  - dev)*this.pcm_data[i].lchnnl);
        $cast(data_max, (1.0  + dev)*this.pcm_data[i].lchnnl);
        $cast(data,     item.pcm_data[i].lchnnl);

        //if(this.pcm_data[i].lchnnl  !=  item.pcm_data[i].lchnnl)
        if((data < data_min) ||  (data  > data_max))
          res = {res,$psprintf("\nMismatch in pcm_data[%1d].lchnnl, expected [0x%x] actual [0x%x]",i,this.pcm_data[i].lchnnl,item.pcm_data[i].lchnnl)};


        $cast(data_min, (1.0  - dev)*this.pcm_data[i].rchnnl);
        $cast(data_max, (1.0  + dev)*this.pcm_data[i].rchnnl);
        $cast(data,     item.pcm_data[i].rchnnl);

        //if(this.pcm_data[i].rchnnl  !=  item.pcm_data[i].rchnnl)
        if((data < data_min) ||  (data  > data_max))
          res = {res,$psprintf("\nMismatch in pcm_data[%1d].rchnnl, expected [0x%x] actual [0x%x]",i,this.pcm_data[i].rchnnl,item.pcm_data[i].rchnnl)};
      end

      return  res;

    endfunction : check

    /*  Function to fill self with Sine/Cosine values */
    function  void  fill_sin(int num_samples,  int freq, int mag,  int fs=44100);

      //this.pcm_data = new[num_samples](this.pcm_data);  //preserve previous data if any
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

    /*  Function to generate a graph of the PCM Data  */
    function  string  get_graph(int ywidth=4);
      string  res = "",tmp;

      for(int i=0;  i<PCM_DATA_W; i+=ywidth)
      begin
        if(i  < 10)
          tmp = $psprintf("%1d\t\t|\t",i);
        else
          tmp = $psprintf("%1d\t|\t",i);

        for(int j=0;  j<this.pcm_data.size; j++)
        begin
          if(this.pcm_data[j].rchnnl  >=  (1  <<  i))
            tmp = $psprintf("%s|",tmp);
          else
            tmp = $psprintf("%s ",tmp);

        end

        res = $psprintf("%s\n%s",tmp,res);
      end

      res = $psprintf("\n\npcm_data.rchnnl  -\n%s",res);


      for(int i=0;  i<PCM_DATA_W; i+=ywidth)
      begin
        if(i  < 10)
          tmp = $psprintf("%1d\t\t|\t",i);
        else
          tmp = $psprintf("%1d\t|\t",i);

        for(int j=0;  j<this.pcm_data.size; j++)
        begin
          if(this.pcm_data[j].lchnnl  >=  (1  <<  i))
            tmp = $psprintf("%s|",tmp);
          else
            tmp = $psprintf("%s ",tmp);

        end

        res = $psprintf("%s\n%s",tmp,res);
      end

      res = $psprintf("pcm_data.lchnnl  -\n%s",res);

      return  res;

    endfunction : get_graph

  endclass  : syn_pcm_seq_item

`endif
