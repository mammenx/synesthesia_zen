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

    `include  "syn_acortex_reg_map.sv"

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

    parameter       NUM_PCM_SAMPLES   = 128;
    parameter type  PCM_MEM_INTF_TYPE = virtual syn_pcm_mem_intf#(32,7);


    /*  Register with factory */
    `ovm_component_utils(syn_acortex_env)

    //Declare agents, scoreboards
    syn_lb_agent#(LB_DATA_W,LB_ADDR_W,LB_PKT_T,LB_DRVR_INTF_T,LB_MON_INTF_T)  lb_agent;
    syn_acortex_codec_agent#( REG_MAP_W,
                              I2C_DATA_W,
                              I2C_INTF_TYPE,
                              I2C_PKT_TYPE,
                              PCM_PKT_TYPE,
                              DAC_INTF_TYPE,
                              ADC_INTF_TYPE
                            )  codec_agent;
    syn_pcm_mem_agent#(NUM_PCM_SAMPLES,PCM_PKT_TYPE,PCM_MEM_INTF_TYPE)        pcm_mem_agent;
    syn_i2c_sb#(I2C_DATA_W,LB_PKT_T,I2C_PKT_TYPE)   i2c_sb;
    syn_adc_sb#(LB_PKT_T,PCM_PKT_TYPE)              adc_sb;
    syn_dac_sb#(LB_PKT_T,PCM_PKT_TYPE)              dac_sb;

    syn_reg_map#(REG_MAP_W)   wm8731_reg_map;  //each register is 9b
    

    OVM_FILE  f;


    //For routing LB packets
    tlm_analysis_fifo#(LB_PKT_T)  LB2Env_ff;
    ovm_analysis_port#(LB_PKT_T)  Env2I2C_Sb_port;
    ovm_analysis_port#(LB_PKT_T)  Env2ADC_Sb_port;
    ovm_analysis_port#(LB_PKT_T)  Env2DAC_Sb_port;


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

      lb_agent      = syn_lb_agent#(LB_DATA_W,LB_ADDR_W,LB_PKT_T,LB_DRVR_INTF_T,LB_MON_INTF_T)::type_id::create("lb_agent",  this);
      codec_agent   = syn_acortex_codec_agent#(REG_MAP_W,I2C_DATA_W,I2C_INTF_TYPE,I2C_PKT_TYPE,PCM_PKT_TYPE,DAC_INTF_TYPE,ADC_INTF_TYPE)::type_id::create("codec_agent",  this);
      pcm_mem_agent = syn_pcm_mem_agent#(NUM_PCM_SAMPLES,PCM_PKT_TYPE,PCM_MEM_INTF_TYPE)::type_id::create("pcm_mem_agent",  this);
      i2c_sb        = syn_i2c_sb#(I2C_DATA_W,LB_PKT_T,I2C_PKT_TYPE)::type_id::create("i2c_sb",  this);
      adc_sb        = syn_adc_sb#(LB_PKT_T,PCM_PKT_TYPE)::type_id::create("adc_sb",  this);
      dac_sb        = syn_dac_sb#(LB_PKT_T,PCM_PKT_TYPE)::type_id::create("dac_sb",  this);

      LB2Env_ff       = new("LB2Env_ff",this);
      Env2I2C_Sb_port = new("Env2I2C_Sb_port",this);
      Env2ADC_Sb_port = new("Env2ADC_Sb_port",this);
      Env2DAC_Sb_port = new("Env2DAC_Sb_port",this);

      wm8731_reg_map     = syn_reg_map#(REG_MAP_W)::type_id::create("wm8731_reg_map",this);
      build_wm8731_reg_map();

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*  Connect */
    function void connect();
      super.connect();

      ovm_report_info(get_name(),"START of connect ",OVM_LOW);

        this.pcm_mem_agent.drvr.mode_master_n_slave  = 0;  //configure as slave

        //Ports
        lb_agent.mon.Mon2Sb_port.connect(this.LB2Env_ff.analysis_export);
        this.Env2I2C_Sb_port.connect(i2c_sb.Mon_lb_2Sb_port);
        this.Env2ADC_Sb_port.connect(adc_sb.Mon_lb_2Sb_port);
        this.Env2DAC_Sb_port.connect(dac_sb.Mon_lb_2Sb_port);
        codec_agent.i2c_mon.Mon2Sb_port.connect(i2c_sb.Mon_i2c_2Sb_port);
        pcm_mem_agent.mon.Mon2Sb_port.connect(adc_sb.Mon_rcvd_2Sb_port);
        codec_agent.adc_mon.Mon2Sb_port.connect(adc_sb.Mon_sent_2Sb_port);

        //Reg Map
        codec_agent.adc_drvr.reg_map  = this.wm8731_reg_map;
        codec_agent.adc_mon.reg_map   = this.wm8731_reg_map;
        codec_agent.dac_mon.reg_map   = this.wm8731_reg_map;
        codec_agent.i2c_slave.reg_map = this.wm8731_reg_map;

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
          case(lb_pkt.addr[i][11:8])

            ACORTEX_I2CM_CODE :
            begin
              ovm_report_info({get_name(),"[run]"},$psprintf("Sending lb_pkt to I2C Scoreboard\n%s",lb_pkt.sprint()),OVM_LOW);
              Env2I2C_Sb_port.put(lb_pkt);
            end

            ACORTEX_WMDRVR_CODE :
            begin
              ovm_report_info({get_name(),"[run]"},$psprintf("Sending lb_pkt to ADC/DAC Scoreboards\n%s",lb_pkt.sprint()),OVM_LOW);
              Env2ADC_Sb_port.put(lb_pkt);
              Env2DAC_Sb_port.put(lb_pkt);
            end

            ACORTEX_ACACHE_CODE :
            begin
              ovm_report_info({get_name(),"[run]"},$psprintf("Sending lb_pkt to ADC/DAC Scoreboards\n%s",lb_pkt.sprint()),OVM_LOW);
              Env2ADC_Sb_port.put(lb_pkt);
              Env2DAC_Sb_port.put(lb_pkt);
            end

            default :
            begin
              ovm_report_warning({get_name(),"[run]"},$psprintf("Nowhere to send pkt ...\n%s",lb_pkt.sprint()),OVM_LOW);
            end

          endcase


          #1;
        end
      end
    endtask : run

    /*
      * This function builds the WM8731 register map as per the spec
    */
    function  void  build_wm8731_reg_map();

      wm8731_reg_map.create_field("linvol",    0,  0,  4);
      wm8731_reg_map.create_field("linmute",   0,  7,  7);
      wm8731_reg_map.create_field("lrinboth",  0,  8,  8);
      wm8731_reg_map.create_field("rinvol",    1,  0,  4);
      wm8731_reg_map.create_field("rinmute",   1,  7,  7);
      wm8731_reg_map.create_field("rlinboth",  1,  8,  8);
      wm8731_reg_map.create_field("lhpvol",    2,  0,  6);
      wm8731_reg_map.create_field("lzcen",     2,  7,  7);
      wm8731_reg_map.create_field("lrhpboth",  2,  8,  8);
      wm8731_reg_map.create_field("rhpvol",    3,  0,  6);
      wm8731_reg_map.create_field("rzcen",     3,  7,  7);
      wm8731_reg_map.create_field("rlhpboth",  3,  8,  8);
      wm8731_reg_map.create_field("micboost",  4,  0,  0);
      wm8731_reg_map.create_field("mutemic",   4,  1,  1);
      wm8731_reg_map.create_field("insel",     4,  2,  2);
      wm8731_reg_map.create_field("bypass",    4,  3,  3);
      wm8731_reg_map.create_field("dacsel",    4,  4,  4);
      wm8731_reg_map.create_field("sdetone",   4,  5,  5);
      wm8731_reg_map.create_field("sideatt",   4,  6,  7);
      wm8731_reg_map.create_field("adchpd",    5,  0,  0);
      wm8731_reg_map.create_field("deemph",    5,  1,  2);
      wm8731_reg_map.create_field("dacmu",     5,  3,  3);
      wm8731_reg_map.create_field("hpor",      5,  4,  4);
      wm8731_reg_map.create_field("lineinpd",  6,  0,  0);
      wm8731_reg_map.create_field("micpd",     6,  1,  1);
      wm8731_reg_map.create_field("adcpd",     6,  2,  2);
      wm8731_reg_map.create_field("dacpd",     6,  3,  3);
      wm8731_reg_map.create_field("outpd",     6,  4,  4);
      wm8731_reg_map.create_field("oscpd",     6,  5,  5);
      wm8731_reg_map.create_field("clkoutpd",  6,  6,  6);
      wm8731_reg_map.create_field("pwroff",    6,  7,  7);
      wm8731_reg_map.create_field("format",    7,  0,  1);
      wm8731_reg_map.create_field("iwl",       7,  2,  3);
      wm8731_reg_map.create_field("lrp",       7,  4,  4);
      wm8731_reg_map.create_field("lrswap",    7,  5,  5);
      wm8731_reg_map.create_field("ms",        7,  6,  6);
      wm8731_reg_map.create_field("bclkinv",   7,  7,  7);
      wm8731_reg_map.create_field("usb/norm",  8,  0,  0);
      wm8731_reg_map.create_field("bosr",      8,  1,  1);
      wm8731_reg_map.create_field("sr",        8,  2,  5);
      wm8731_reg_map.create_field("clk1div2",  8,  6,  6);
      wm8731_reg_map.create_field("clk0div2",  8,  7,  7);
      wm8731_reg_map.create_field("active",    9,  0,  0);

    endfunction : build_wm8731_reg_map

  endclass  : syn_acortex_env

`endif
