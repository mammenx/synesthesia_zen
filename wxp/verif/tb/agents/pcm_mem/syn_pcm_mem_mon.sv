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
 -- Component Name    : syn_pcm_mem_mon
 -- Author            : mammenx
 -- Function          : This class monitors the PCM cache interface from
                        Acortex to Fgyrus & sends packets to scoreboard.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_PCM_MEM_MON
`define __SYN_PCM_MEM_MON

  class syn_pcm_mem_mon #(parameter NUM_SAMPLES = 128,
                          parameter type  PKT_TYPE  = syn_pcm_seq_item,
                          parameter type  INTF_TYPE = virtual syn_pcm_mem_intf
                        ) extends ovm_component;

    INTF_TYPE intf;

    ovm_analysis_port #(PKT_TYPE) Mon2Sb_port;

    OVM_FILE  f;

    PKT_TYPE  pkt;

    shortint  enable;

    /*  Register with factory */
    `ovm_component_param_utils(syn_pcm_mem_mon#(NUM_SAMPLES,PKT_TYPE, INTF_TYPE))


    /*  Constructor */
    function new( string name = "syn_pcm_mem_mon" , ovm_component parent = null) ;
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
      int lpcm_addr_1d,lpcm_addr_2d;
      int rpcm_addr_1d,rpcm_addr_2d;

      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      //wait for reset

      if(enable)
      begin
        fork
          //begin //get delayed addresses
          //  @(posedge intf.clk_ir);
          //  lpcm_addr_2d = lpcm_addr_1d;
          //  lpcm_addr_1d = intf.cb.pcm_addr;

          //  rpcm_addr_2d = rpcm_addr_1d;
          //  rpcm_addr_1d = intf.cb.pcm_addr;
          //end

          begin
            forever
            begin
              //Monitor logic
              ovm_report_info({get_name(),"[run]"},"Waiting for pcm_data_rdy pulse",OVM_LOW);
              @(posedge intf.cb.pcm_data_rdy);
              ovm_report_info({get_name(),"[run]"},"Detected pcm_data_rdy pulse",OVM_LOW);
              @(posedge intf.clk_ir);

              pkt = new();

              pkt.pcm_data  = new[NUM_SAMPLES];

              forever
              begin
                @(posedge intf.clk_ir);

                lpcm_addr_2d  = intf.cb.pcm_raddr;
                rpcm_addr_2d  = intf.cb.pcm_raddr;

                if(intf.cb.pcm_rd_valid)
                begin
                  pkt.pcm_data[lpcm_addr_2d].lchnnl = intf.cb.lpcm_rdata;
                  pkt.pcm_data[rpcm_addr_2d].rchnnl = intf.cb.rpcm_rdata;

                  ovm_report_info({get_name(),"[run]"},$psprintf("pkt.pcm_data[%1d].lchnnl = 0x%x",lpcm_addr_2d,pkt.pcm_data[lpcm_addr_2d].lchnnl),OVM_LOW);
                  ovm_report_info({get_name(),"[run]"},$psprintf("pkt.pcm_data[%1d].rchnnl = 0x%x",rpcm_addr_2d,pkt.pcm_data[rpcm_addr_2d].rchnnl),OVM_LOW);

                  if((lpcm_addr_2d  ==  NUM_SAMPLES-1)  ||  (rpcm_addr_2d ==  NUM_SAMPLES-1))
                    break;
                end
              end

              @(posedge intf.clk_ir);

              //Send captured pkt to SB
              ovm_report_info({get_name(),"[run]"},$psprintf("Sending pkt to SB -\n%s", pkt.sprint()),OVM_LOW);
              Mon2Sb_port.write(pkt);
            end
          end
        join
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_pcm_mem_mon  is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run


  endclass  : syn_pcm_mem_mon

`endif
