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
 -- Component Name    : syn_acortex_env
 -- Author            : mammenx
 -- Function          : This is the complete verif environment for Acortex
                        block.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/


`ifndef __SYN_ACORTEX_ENV
`define __SYN_ACORTEX_ENV


  class syn_acortex_env extends ovm_env;

    //Parameters
    parameter       LB_DATA_W   = 32;
    parameter       LB_ADDR_W   = 12;
    parameter type  LB_PKT_T    = syn_lb_seq_item#(LB_DATA_W,LB_ADDR_W);
    parameter type  LB_DRVR_INTF_T  = virtual syn_lb_tb_intf#(LB_DATA_W,LB_ADDR_W);
    parameter type  LB_MON_INTF_T   = virtual syn_lb_tb_intf#(LB_DATA_W,LB_ADDR_W);

    parameter       REG_MAP_W     = 9;

    parameter       I2C_DATA_W    = 16;
    parameter type  I2C_INTF_TYPE = virtual syn_wm8731_intf.TB_I2C;
    parameter type  I2C_PKT_TYPE  = syn_lb_seq_item#(8, 7); //8b data & 7b address

    parameter type  PCM_PKT_TYPE  = syn_pcm_seq_item;

    parameter type  DAC_INTF_TYPE = virtual syn_wm8731_intf.TB_DAC;
    parameter type  ADC_INTF_TYPE = virtual syn_wm8731_intf.TB_ADC;


    /*  Register with factory */
    `ovm_component_utils(syn_acortex_env)

    //Declare agensts, scoreboards
    syn_lb_agent#(LB_DATA_W,LB_ADDR_W,LB_PKT_T,LB_DRVR_INTF_T,LB_MON_INTF_T)  lb_agent;
    syn_acortex_codec_agent#(REG_MAP_W,I2C_DATA_W,I2C_INTF_TYPE,I2C_PKT_TYPE,PCM_PKT_TYPE,DAC_INTF_TYPE,ADC_INTF_TYPE)  codec_agent;
    syn_i2c_sb#(I2C_DATA_W,LB_PKT_T,I2C_PKT_TYPE)   i2c_sb;


    OVM_FILE  f;


    //For routing LB packets
    tlm_analysis_fifo#(LB_PKT_T)  LB2Env_ff;
    ovm_analysis_port#(LB_PKT_T)  Env2I2C_Sb_port;


    /*  Constructor */
    function new(string name  = "syn_acortex_env", ovm_component parent = null);
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

      lb_agent    = syn_lb_agent#(LB_DATA_W,LB_ADDR_W,LB_PKT_T,LB_DRVR_INTF_T,LB_MON_INTF_T)::type_id::create("lb_agent",  this);
      codec_agent = syn_acortex_codec_agent#(REG_MAP_W,I2C_DATA_W,I2C_INTF_TYPE,I2C_PKT_TYPE,PCM_PKT_TYPE,DAC_INTF_TYPE,ADC_INTF_TYPE)::type_id::create("codec_agent",  this);
      i2c_sb      = syn_i2c_sb#(I2C_DATA_W,LB_PKT_T,I2C_PKT_TYPE)::type_id::create("i2c_sb",  this);

      LB2Env_ff       = new("LB2Env_ff",this);
      Env2I2C_Sb_port = new("Env2I2C_Sb_port",this);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*  Connect */
    function void connect();
      super.connect();

      ovm_report_info(get_name(),"START of connect ",OVM_LOW);

        lb_agent.mon.Mon2Sb_port.connect(this.LB2Env_ff.analysis_export);
        this.Env2I2C_Sb_port.connect(i2c_sb.Mon_lb_2Sb_port);
        codec_agent.i2c_mon.Mon_i2c_2Sb_port.connect(i2c_sb.Mon_i2c_2Sb_port);

      ovm_report_info(get_name(),"END of connect ",OVM_LOW);
    endfunction

    /*  Run */
    task  run();
      LB_PKT_T  lb_pkt;

      ovm_report_info({get_name(),"[run]"},"START of run ...",OVM_LOW);

      forever
      begin
        LB2Env_ff.get(lb_pkt);

        foreach(lb_pkt.addr[i])
        begin
          if(lb_pkt.addr[i][11:8] ==  ACORTEX_I2CM_CODE)
          begin
            Env2I2C_Sb_port.put(lb_pkt);
          end

          #1;
        end
      end
    endtask : run

  endclass  : syn_acortex_env

`endif
