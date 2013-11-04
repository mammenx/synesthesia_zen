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
 -- Component Name    : syn_lb_seq_item
 -- Author            : mammenx
 -- Function          : This class describes a typical localbus transaction
                        item. Can be used for simple memory xtns as well.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_LB_SEQ_ITEM
`define __SYN_LB_SEQ_ITEM


  typedef enum  {READ=0, WRITE=1, BURST_READ=2, BURST_WRITE=3}  lb_xtn_t;

  class syn_lb_seq_item #(parameter DATA_W  = 32,
                          parameter ADDR_W  = 16
                        ) extends ovm_sequence_item;

    //fields
    rand  bit [ADDR_W-1:0]  addr[];
    rand  bit [DATA_W-1:0]  data[];
    rand  lb_xtn_t          lb_xtn;

    //registering with factory
    `ovm_object_param_utils_begin(syn_lb_seq_item#(DATA_W,ADDR_W))
      `ovm_field_array_int(addr,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_array_int(data,  OVM_ALL_ON | OVM_HEX);
      `ovm_field_enum(lb_xtn_t, lb_xtn,  OVM_ALL_ON  | OVM_ENUM);
    `ovm_object_utils_end

    /*  Constructor */
    function new(string name = "syn_lb_seq_item");
      super.new(name);
    endfunction : new


    /*  Constraint  Block */
    constraint  c_burst_len_lim {
                                  if((lb_xtn  ==  READ) ||  (lb_xtn ==  WRITE)) {
                                    addr.size ==  1;
                                    data.size ==  1;
                                  }

                                  addr.size   ==  data.size;

                                  solve lb_xtn  before  addr;
                                  solve addr    before  data;
                                }

    /*  Function to check a pkt of same type */
    function  bit check (input  syn_lb_seq_item#(DATA_W,ADDR_W) item);

      if(this.addr.size !=  item.addr.size) return  0;

      if(this.data.size !=  item.data.size) return  0;

      if(this.lb_xtn  !=  item.lb_xtn)      return  0;

      foreach(this.addr[i])
      begin
        if(this.addr[i] !=  item.addr[i])   return  0;
      end

      foreach(this.data[i])
      begin
        if(this.data[i] !=  item.data[i])   return  0;
      end

      return  1;

    endfunction : check

    function  string  checkString (input  syn_lb_seq_item#(DATA_W,ADDR_W) item);
      string  res = "";

      if(this.addr.size !=  item.addr.size)
      begin
        $psprintf("%s\nExpected addr.size[%1d], Actual addr.size[%1d]",res,this.addr.size,item.addr.size);
      end
      else
      begin
        for(int i=0;  i<this.addr.size; i++)
        begin
          if(this.addr[i] !=  item.addr[i]) res = $psprintf("%s\nExpected addr[%1d]:0x%x, Actual addr[%1d]:0x%x",res,i,this.addr[i],i,item.addr[i]);
        end
      end

      if(this.data.size !=  item.data.size)
      begin
        $psprintf("%s\nExpected data.size[%1d], Actual data.size[%1d]",res,this.data.size,item.data.size);
      end
      else
      begin
        for(int k=0;  k<this.data.size; k++)
        begin
          if(this.data[k] !=  item.data[k]) res = $psprintf("%s\nExpected data[%1d]:0x%x, Actual data[%1d]:0x%x",res,k,this.data[k],k,item.data[k]);
        end
      end

      if(this.lb_xtn  !=  item.lb_xtn)      res = $psprintf("%s\nExpected lb_xtn[%s], Actual lb_xtn[%s]",res,this.lb_xtn.name,item.lb_xtn.name);

      return  res;

    endfunction : checkString


  endclass  : syn_lb_seq_item

`endif
