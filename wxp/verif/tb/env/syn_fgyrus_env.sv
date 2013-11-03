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
 -- Component Name    : syn_fgyrus_env
 -- Author            : mammenx
 -- Function          : This environment holds all the agents needed to
                        interact with Fgyrus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


`ifndef __SYN_FGYRUS_ENV
`define __SYN_FGYRUS_ENV


  class syn_fgyrus_env extends ovm_env;

    `include  "syn_fgyrus_reg_map.sv"

    //Parameters
    parameter       LB_DATA_W   = 32;
    parameter       LB_ADDR_W   = 12;
    parameter type  LB_PKT_T    = syn_lb_seq_item#(LB_DATA_W,LB_ADDR_W);
    parameter type  LB_DRVR_INTF_T  = virtual syn_lb_tb_intf#(LB_DATA_W,LB_ADDR_W);
    parameter type  LB_MON_INTF_T   = virtual syn_lb_tb_intf#(LB_DATA_W,LB_ADDR_W);

    parameter type  PCM_PKT_TYPE  = syn_pcm_seq_item;
    parameter       NUM_PCM_SAMPLES   = 128;
    parameter type  PCM_MEM_INTF_TYPE = virtual syn_pcm_mem_intf#(32,7,2);

    parameter type  BUT_PKT_TYPE  = syn_but_seq_item;
    parameter type  BUT_INTF_TYPE = virtual syn_but_intf;

    parameter type  FFT_CACHE_PKT_TYPE  = syn_fft_cache_seq_item;
    parameter type  FFT_CACHE_INTF_TYPE = virtual syn_fft_cache_intf#(32,8);

    /*  Register with factory */
    `ovm_component_utils(syn_fgyrus_env)


    //Declare agents, scoreboards
    syn_lb_agent#(LB_DATA_W,LB_ADDR_W,LB_PKT_T,LB_DRVR_INTF_T,LB_MON_INTF_T)  lb_agent;
    syn_pcm_mem_agent#(NUM_PCM_SAMPLES,PCM_PKT_TYPE,PCM_MEM_INTF_TYPE)        pcm_mem_agent;
    syn_but_sniffer#(BUT_PKT_TYPE,BUT_INTF_TYPE)                              but_sniffer;
    syn_but_sb#(BUT_PKT_TYPE,BUT_PKT_TYPE)                                    but_sb;
    syn_fft_sb#(PCM_PKT_TYPE,PCM_PKT_TYPE)                                    fft_sb;
    syn_fft_cache_sniffer#(FFT_CACHE_PKT_TYPE,FFT_CACHE_INTF_TYPE)            fft_cache_sniffer;
    syn_fft_cache_sb#(PCM_PKT_TYPE,FFT_CACHE_PKT_TYPE)                        fft_cache_sb;


    OVM_FILE  f;

    //For handling LB pkts
    syn_reg_map#(LB_DATA_W)       fgyrus_reg_map;
    tlm_analysis_fifo#(LB_PKT_T)  LB2Env_ff;
    ovm_analysis_port#(PCM_PKT_TYPE)  Env2FFT_Sb_port;


    /*  Constructor */
    function new(string name  = "syn_fgyrus_env", ovm_component parent = null);
      super.new(name, parent);
    endfunction: new


    /*  Build */
    function void build();
      super.build();

      f = $fopen({"./logs/",get_full_name(),".log"});

      set_report_default_file(f);
      set_report_severity_action(OVM_INFO,  OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_WARNING, OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_ERROR,  OVM_COUNT | OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_FATAL,  OVM_EXIT | OVM_DISPLAY | OVM_LOG);

      ovm_report_info(get_name(),"Start of build ",OVM_LOW);

      lb_agent      = syn_lb_agent#(LB_DATA_W,LB_ADDR_W,LB_PKT_T,LB_DRVR_INTF_T,LB_MON_INTF_T)::type_id::create("lb_agent",  this);
      pcm_mem_agent = syn_pcm_mem_agent#(NUM_PCM_SAMPLES,PCM_PKT_TYPE,PCM_MEM_INTF_TYPE)::type_id::create("pcm_mem_agent",  this);
      but_sniffer   = syn_but_sniffer#(BUT_PKT_TYPE,BUT_INTF_TYPE)::type_id::create("but_sniffer",  this);
      but_sb        = syn_but_sb#(BUT_PKT_TYPE,BUT_PKT_TYPE)::type_id::create("but_sb",  this);
      fft_sb        = syn_fft_sb#(PCM_PKT_TYPE,PCM_PKT_TYPE)::type_id::create("fft_sb",  this);
      fft_cache_sniffer = syn_fft_cache_sniffer#(FFT_CACHE_PKT_TYPE,FFT_CACHE_INTF_TYPE)::type_id::create("fft_cache_sniffer",  this);
      fft_cache_sb  = syn_fft_cache_sb#(PCM_PKT_TYPE,FFT_CACHE_PKT_TYPE)::type_id::create("fft_cache_sb",  this);

      fgyrus_reg_map= syn_reg_map#(LB_DATA_W)::type_id::create("fgyrus_reg_map",this);

      LB2Env_ff       = new("LB2Env_ff",this);
      Env2FFT_Sb_port = new("Env2FFT_Sb_port",this);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*  Connect */
    function void connect();
      super.connect();

      ovm_report_info(get_name(),"START of connect ",OVM_LOW);

        lb_agent.mon.Mon2Sb_port.connect(this.LB2Env_ff.analysis_export);
      
        this.pcm_mem_agent.drvr.mode_master_n_slave  = 1;  //configure as master

        but_sniffer.SnifferIngr2Sb_port.connect(but_sb.Mon_sent_2Sb_port);
        but_sniffer.SnifferEgr2Sb_port.connect(but_sb.Mon_rcvd_2Sb_port);

        this.pcm_mem_agent.mon.Mon2Sb_port.connect(fft_sb.Mon_sent_2Sb_port);
        this.Env2FFT_Sb_port.connect(fft_sb.Mon_rcvd_2Sb_port);

        this.pcm_mem_agent.mon.Mon2Sb_port.connect(fft_cache_sb.Mon_sent_2Sb_port);
        this.fft_cache_sniffer.Sniffer2Sb_port.connect(fft_cache_sb.Mon_rcvd_2Sb_port);

        build_fgyrus_reg_map();
        ovm_report_info(get_name(),$psprintf("Fgyrus Reg Map Table%s",fgyrus_reg_map.sprintTable()),OVM_LOW);

      ovm_report_info(get_name(),"END of connect ",OVM_LOW);
    endfunction


    /*  This function build the Fgyrus reg map  */
    function  void  build_fgyrus_reg_map();

      fgyrus_reg_map.create_field("en",         {FGYRUS_REG_CODE,FGYRUS_CONTROL_REG_ADDR},    0,  0);
      fgyrus_reg_map.create_field("mode",       {FGYRUS_REG_CODE,FGYRUS_CONTROL_REG_ADDR},    1,  1);
      fgyrus_reg_map.create_field("post_norm",  {FGYRUS_REG_CODE,FGYRUS_POST_NORM_REG_ADDR},  0,  3);
      fgyrus_reg_map.create_field("cache_addr", {FGYRUS_REG_CODE,FGYRUS_FFT_CACHE_ADDR},      0,  8);

      //fgyrus_reg_map.create_space("fft_cache",  {FGYRUS_FFT_CACHE_RAM_CODE,8'd0}, 256);
      //fgyrus_reg_map.create_space("twdl_ram",   {FGYRUS_TWDLE_RAM_CODE,8'd0},     128);
      //fgyrus_reg_map.create_space("cordic_ram", {FGYRUS_CORDIC_RAM_CODE,8'd0},    256);
      //fgyrus_reg_map.create_space("win_ram",    {FGYRUS_WIN_RAM_CODE,8'd0},       128);

    endfunction : build_fgyrus_reg_map

    /*  Run */
    task  run();
      LB_PKT_T  lb_pkt;
      PCM_PKT_TYPE  fft_pkt;

      ovm_report_info({get_name(),"[run]"},"START of run ...",OVM_LOW);

      forever
      begin
        LB2Env_ff.get(lb_pkt);  //wait for LB pkt

        ovm_report_info({get_name(),"[run]"},$psprintf("Received lb pkt:\n%s",lb_pkt.sprint()),OVM_LOW);

        if((lb_pkt.lb_xtn ==  WRITE)  ||  (lb_pkt.lb_xtn  ==  BURST_WRITE))
        begin
          foreach(lb_pkt.addr[i])
          begin
            if(fgyrus_reg_map.set_reg(lb_pkt.addr[i], lb_pkt.data[i]) !=  syn_reg_map#(LB_DATA_W)::SUCCESS)
              ovm_report_fatal({get_name(),"[run]"},$psprintf("Addr 0x%x does not exist",lb_pkt.addr[i]),OVM_LOW);
          end
        end
        else  //read
        begin
          if((lb_pkt.addr[0][11:8]  ==  FGYRUS_FFT_CACHE_RAM_CODE)  &&  (lb_pkt.addr.size ==  256))
          begin
            //create the FFT pkt for fft_sb
            fft_pkt = new();
            fft_pkt.pcm_data  = new[128];

            for(int i=0; i<128; i++)
            begin
              $cast(fft_pkt.pcm_data[i].lchnnl, lb_pkt.data[i]);
              $cast(fft_pkt.pcm_data[i].rchnnl, lb_pkt.data[i+128]);
            end

            ovm_report_info({get_name(),"[run]"},$psprintf("Sending FFT pkt to fft_sb:\n%s",fft_pkt.sprint()),OVM_LOW);
            Env2FFT_Sb_port.write(fft_pkt);
          end
        end
      end
    endtask : run

  endclass  : syn_fgyrus_env

`endif
