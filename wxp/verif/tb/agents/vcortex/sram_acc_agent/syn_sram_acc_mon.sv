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
 -- Component Name    : syn_sram_acc_mon
 -- Author            : mammenx
 -- Function          : This is a monitor for a sram agent access interface
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_SRAM_ACC_MON
`define __SYN_SRAM_ACC_MON

 class syn_sram_acc_mon   #(parameter DATA_W  = 16,
                            parameter ADDR_W  = 18,
                            type  PKT_TYPE    = syn_lb_seq_item,
                            type  INTF_TYPE   = virtual syn_sram_acc_agent_intf
                          ) extends ovm_component;

    INTF_TYPE intf;

    ovm_analysis_port #(PKT_TYPE) Mon2Sb_port;

    OVM_FILE  f;

    PKT_TYPE  rd_pkt,wr_pkt;

    shortint  enable;

    /*  Register with factory */
    `ovm_component_param_utils_begin(syn_sram_acc_mon#(DATA_W,ADDR_W,PKT_TYPE, INTF_TYPE))
      `ovm_field_int(enable,  OVM_ALL_ON);
    `ovm_component_utils_end


    /*  Constructor */
    function new( string name = "syn_sram_acc_mon" , ovm_component parent = null) ;
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

      wr_pkt = new();
      rd_pkt = new();

      enable  = 1;  //Enabled by default; disable from test case

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    /*  Run */
    task run();
      bit [ADDR_W-1:0]  addr[$];
      bit [DATA_W-1:0]  data[$];

      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      if(enable)
      begin
        //wait for reset
        @(posedge intf.rst_il);

        fork
          begin
            forever
            begin
              @(posedge intf.clk_ir iff (intf.cb.wr_en & intf.cb.rdy) ==  1); //wait for enable to be asserted

              wr_pkt = new();
              wr_pkt.lb_xtn  = WRITE;

              while(intf.cb.wr_en & intf.cb.rdy)
              begin
                wr_pkt.addr = new[wr_pkt.addr.size  + 1](wr_pkt.addr);  //expand & copy
                wr_pkt.addr[wr_pkt.addr.size-1] = intf.cb.addr;

                wr_pkt.data = new[wr_pkt.data.size  + 1](wr_pkt.data);  //expand & copy
                wr_pkt.data[wr_pkt.data.size-1] = intf.cb.wr_data;

                @(posedge intf.clk_ir);
              end

              //Send captured wr_pkt to SB
              ovm_report_info({get_name(),"[run]"},$psprintf("Sending wr_pkt to SB -\n%s", wr_pkt.sprint()),OVM_LOW);
              Mon2Sb_port.write(wr_pkt);
            end
          end

          begin
            forever
            begin
              @(posedge intf.clk_ir iff (intf.cb.rd_en & intf.cb.rdy) ==  1); //wait for enable to be asserted

              while(intf.cb.rd_en & intf.cb.rdy)
              begin
                addr.push_back(intf.cb.addr);
                @(posedge intf.clk_ir);
              end
            end
          end

          begin
            forever
            begin
              @(posedge intf.clk_ir iff intf.cb.rd_valid  ==  1); //wait for rd_valid to be asserted

              rd_pkt = new();
              rd_pkt.lb_xtn  = READ;

              while(intf.cb.rd_valid)
              begin
                rd_pkt.addr = new[rd_pkt.addr.size  + 1](rd_pkt.addr);  //expand & copy
                rd_pkt.addr[rd_pkt.addr.size-1] = addr.pop_front();

                rd_pkt.data = new[rd_pkt.data.size  + 1](rd_pkt.data);  //expand & copy
                rd_pkt.data[rd_pkt.data.size-1] = intf.cb.rd_data;

                @(posedge intf.clk_ir);
              end

              //Send captured rd_pkt to SB
              ovm_report_info({get_name(),"[run]"},$psprintf("Sending rd_pkt to SB -\n%s", rd_pkt.sprint()),OVM_LOW);
              Mon2Sb_port.write(rd_pkt);
            end
          end
        join
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_sram_acc_mon  is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run


  endclass  : syn_sram_acc_mon

`endif
