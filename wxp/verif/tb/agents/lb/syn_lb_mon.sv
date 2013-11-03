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
 -- Component Name    : syn_lb_mon
 -- Author            : mammenx
 -- Function          : This is a monitor for a generic LB interface
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_LB_MON
`define __SYN_LB_MON

 class syn_lb_mon   #(parameter DATA_W  = 32,
                      parameter ADDR_W  = 16,
                      type  PKT_TYPE    = syn_lb_seq_item,
                      type  INTF_TYPE   = virtual syn_lb_intf
                    ) extends ovm_component;

    INTF_TYPE intf;

    ovm_analysis_port #(PKT_TYPE) Mon2Sb_port;

    OVM_FILE  f;

    PKT_TYPE  pkt;

    shortint  enable;

    /*  Register with factory */
    `ovm_component_param_utils_begin(syn_lb_mon#(DATA_W,ADDR_W,PKT_TYPE, INTF_TYPE))
      `ovm_field_int(enable,  OVM_ALL_ON);
    `ovm_component_utils_end


    /*  Constructor */
    function new( string name = "syn_lb_mon" , ovm_component parent = null) ;
      super.new( name , parent );
    endfunction : new


    /*  Build */
    function  void  build();
      super.build();

      f = $fopen({"./logs/",get_full_name(),".log"},  "w");

      set_report_default_file(f);
      set_report_severity_action(OVM_INFO,  OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_WARNING, OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_ERROR,  OVM_COUNT | OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_FATAL,  OVM_EXIT | OVM_DISPLAY | OVM_LOG);

      ovm_report_info(get_name(),"Start of build ",OVM_LOW);

      Mon2Sb_port = new("Mon2Sb_port", this);

      pkt = new();

      enable  = 1;  //Enabled by default; disable from test case

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    /*  Run */
    task run();
      bit [ADDR_W-1:0]  addr[$];
      bit [DATA_W-1:0]  data[$];

      /*  Check if the parameters are in sync!  */
      //  if(intf.addr.size !=  ADDR_W)
      //     ovm_report_fatal({get_name(),"[run]"},$psprintf("Intf addr_w(%d) does not match ADDR_W(%d) !!!",intf.addr.size,ADDR_W),OVM_LOW);

      //  if(intf.wr_data.size !=  DATA_W)
      //     ovm_report_fatal({get_name(),"[run]"},$psprintf("Intf wr_data_w(%d) does not match DATA_W(%d) !!!",intf.wr_data.size,DATA_W),OVM_LOW);

      //  if(intf.rd_data.size !=  DATA_W)
      //     ovm_report_fatal({get_name(),"[run]"},$psprintf("Intf rd_data_w(%d) does not match DATA_W(%d) !!!",intf.rd_data.size,DATA_W),OVM_LOW);


      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      if(enable)
      begin
        //wait for reset
        @(posedge intf.rst_il);

        forever
        begin
          //Monitor logic
          @(posedge intf.clk_ir iff (intf.cb.rd_en | intf.cb.wr_en) ==  1); //wait for enable to be asserted

          addr  = {}; //clear queues
          data  = {};

          pkt = new();
          pkt.lb_xtn  = intf.cb.wr_en ? WRITE : READ;

          fork
            //capture address
            begin
              while(intf.cb.wr_en ||  intf.cb.rd_en)
              begin
                addr.push_back(intf.cb.addr);
                @(posedge intf.clk_ir);
              end
            end

            //capture data
            begin
              if(pkt.lb_xtn ==  WRITE)
              begin
                while(intf.cb.wr_en)
                begin
                  data.push_back(intf.cb.wr_data);
                  @(posedge intf.clk_ir);
                end
              end
              else  //READ
              begin
                @(posedge intf.cb.rd_valid);  //wait for read valid

                while(intf.cb.rd_valid)
                begin
                  data.push_back(intf.cb.rd_data);
                  @(posedge intf.clk_ir);
                end
              end
            end
          join  //join_all

          //Pack contents into pkt
          pkt.addr  = new[addr.size];
          pkt.data  = new[data.size];

          foreach(pkt.addr[i])
            pkt.addr[i] = addr.pop_front();

          foreach(pkt.data[i])
            pkt.data[i] = data.pop_front();

          if(pkt.addr.size  > 1)
          begin
            if(pkt.lb_xtn ==  READ)
            begin
              pkt.lb_xtn  = BURST_READ;
            end
            else
            begin
              pkt.lb_xtn  = BURST_WRITE;
            end
          end

          //Send captured pkt to SB
          ovm_report_info({get_name(),"[run]"},$psprintf("Sending pkt to SB -\n%s", pkt.sprint()),OVM_LOW);
          Mon2Sb_port.write(pkt);
          #1;
        end
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_lb_mon  is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run


  endclass  : syn_lb_mon

`endif
