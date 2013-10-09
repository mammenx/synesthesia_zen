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
 -- Component Name    : syn_pcm_mem_drvr
 -- Author            : mammenx
 -- Function          : This class is responsible for issuing/responding to
                        PCM read xtns from Acortex to Fgyrus. It can act as
                        either master or slave, depending on how it is
                        configured.                        
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_PCM_MEM_DRVR
`define __SYN_PCM_MEM_DRVR

  import  syn_audio_pkg::*;

  class syn_pcm_mem_drvr  #(parameter NUM_SAMPLES = 128,
                            parameter type  PKT_TYPE  = syn_pcm_seq_item,
                            parameter type  INTF_TYPE = virtual syn_pcm_mem_intf
                          ) extends ovm_driver  #(PKT_TYPE,PKT_TYPE); //request, response

    INTF_TYPE intf;

    OVM_FILE  f;

    shortint  enable;
    bit       mode_master_n_slave;


    /*  Register with factory */
    `ovm_component_param_utils_begin(syn_pcm_mem_drvr#(NUM_SAMPLES, PKT_TYPE, INTF_TYPE))
      `ovm_field_int(enable,  OVM_ALL_ON);
      `ovm_field_int(mode_master_n_slave,  OVM_ALL_ON);
    `ovm_component_utils_end


    /*  Constructor */
    function new( string name = "syn_pcm_mem_drvr" , ovm_component parent = null) ;
      super.new( name , parent );

      enable    = 1;  //by default enabled; disable from test case

      mode_master_n_slave = 1;  //is master by default; change from environment.
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


      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    /*  Run */
    task run();
      PKT_TYPE  pkt_rsp;

      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      //Wait for reset  ...
      //@(posedge intf.rst_il);
      //#100ns;

      if(enable)
      begin
        if(mode_master_n_slave)
          run_master();
        else
          run_slave();
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_pcm_mem_drvr is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run


    /*  Run Master Behaviour  */
    task  run_master  ();
      PKT_TYPE  pkt = new();
      pcm_data_t  pcm_data[];
      bit [31:0]  lpcm_rdata_1d,lpcm_rdata_2d;
      bit         pcm_rd_valid_1d,pcm_rd_valid_2d;
      int         pcm_addr_1d;

      ovm_report_info({get_name(),"[run_master]"},"Start of run_master",OVM_LOW);

      //Reset signals
      intf.cb.pcm_data_rdy  <= 0;
      intf.cb.lpcm_rdata    <= 0;
      intf.cb.rpcm_rdata    <= 0;
      intf.cb.pcm_rd_valid  <= 0;

      //Wait for reset ...
      @(posedge intf.rst_il);
      #100;

      pcm_data  = new[NUM_SAMPLES];

      fork
        begin //wait for next seq items & update PCM data
          forever
          begin
            ovm_report_info({get_name(),"[run_master]"},"Waiting for seq_item",OVM_LOW);
            seq_item_port.get_next_item(pkt);

            ovm_report_info({get_name(),"[run_master]"},$psprintf("Got seq_item - \n%s",pkt.sprint()),OVM_LOW);

            //update pcm data
            foreach(pcm_data[i])
            begin
              pcm_data[i].lchnnl  = pkt.pcm_data[i].lchnnl;
              pcm_data[i].rchnnl  = pkt.pcm_data[i].rchnnl;
            end

            //send pcm_data_rdy pulse
            ovm_report_info({get_name(),"[run_master]"},$psprintf("Sending PCM Data Ready pulse"),OVM_LOW);
            @(posedge intf.clk_ir);

            intf.cb.pcm_data_rdy  <=  1;
            @(posedge intf.clk_ir);
            intf.cb.pcm_data_rdy  <=  0;

            @(posedge intf.clk_ir);
            seq_item_port.item_done();
          end
        end

        begin //respond to read/write
          forever
          begin
            @(posedge intf.clk_ir);

            if(intf.cb.pcm_wren)
            begin
              pcm_data[intf.cb.pcm_addr].lchnnl = intf.cb.lpcm_wdata;
              pcm_data[intf.cb.pcm_addr].rchnnl = intf.cb.rpcm_wdata;
            end

            //intf.cb.lpcm_rdata  <=  pcm_data[intf.cb.pcm_raddr];
            //intf.cb.rpcm_rdata  <=  pcm_data[intf.cb.pcm_raddr];
            intf.cb.lpcm_rdata  <=  pcm_data[pcm_addr_1d].lchnnl;
            intf.cb.rpcm_rdata  <=  pcm_data[pcm_addr_1d].rchnnl;
            pcm_addr_1d = intf.cb.pcm_addr;

            //intf.cb.pcm_rd_valid  <=  pcm_rd_valid_2d;
            intf.cb.pcm_rd_valid  <=  pcm_rd_valid_1d;
            pcm_rd_valid_2d = pcm_rd_valid_1d;
            pcm_rd_valid_1d = intf.cb.pcm_rden;
          end
        end
      join

      ovm_report_info({get_name(),"[run_master]"},"End of run",OVM_LOW);
    endtask : run_master


    /*  Run Slave Behaviour */
    task  run_slave  ();
      ovm_report_info({get_name(),"[run_slave]"},"Start of run_slave",OVM_LOW);

      //Reset signals
      intf.cb.pcm_addr    <=  0;
      intf.cb.pcm_wren    <=  0;
      intf.cb.lpcm_wdata  <=  0;
      intf.cb.rpcm_wdata  <=  0;
      intf.cb.pcm_rden    <=  0;

      //Wait for reset ...
      @(posedge intf.rst_il);
      #100;

      forever
      begin
        ovm_report_info({get_name(),"[run_slave]"},"Waiting for pcm_data_rdy pulse",OVM_LOW);
        @(posedge intf.cb.pcm_data_rdy);  //wait for pulse
        ovm_report_info({get_name(),"[run_slave]"},"Detected pcm_data_rdy pulse",OVM_LOW);

        @(posedge intf.clk_ir);

        intf.cb.pcm_addr    <=  0;
        intf.cb.pcm_rden    <=  1;

        @(posedge intf.clk_ir);

        repeat(NUM_SAMPLES-1)
        begin
          intf.cb.pcm_addr  <=  intf.cb.pcm_addr  + 1;

          @(posedge intf.clk_ir);
        end

        intf.cb.pcm_rden    <=  0;

        @(posedge intf.clk_ir);
      end

      ovm_report_info({get_name(),"[run_slave]"},"End of run",OVM_LOW);
    endtask : run_slave


  endclass  : syn_pcm_mem_drvr

`endif
