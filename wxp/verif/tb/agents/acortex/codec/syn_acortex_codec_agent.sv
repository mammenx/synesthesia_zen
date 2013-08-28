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
 -- Component Name    : syn_acortex_codec_agent
 -- Author            : mammenx
 -- Function          : This is the WM8731 Audio Codec Agent, that contains
                        all the components required.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_ACORTEX_CODEC_AGENT
`define __SYN_ACORTEX_CODEC_AGENT

  class syn_acortex_codec_agent #(
                                  parameter       REG_MAP_W     = 9,
                                  parameter       I2C_DATA_W    = 16,
                                  parameter type  I2C_INTF_TYPE = virtual syn_wm8731_intf.TB_I2C,
                                  parameter type  PKT_TYPE      = syn_pcm_seq_item,
                                  parameter type  DAC_INTF_TYPE = virtual syn_wm8731_intf.TB_DAC,
                                  parameter type  ADC_INTF_TYPE = virtual syn_wm8731_intf.TB_ADC
                                ) extends ovm_component;

    /*  Register with factory */
    `ovm_component_utils(syn_acortex_codec_agent)

    //Declare Seqr, Drvr, Mon, Sb objects
    syn_acortex_codec_i2c_slave#(REG_MAP_W, I2C_DATA_W, I2C_INTF_TYPE)  i2c_slave;
    syn_acortex_codec_dac_mon#(REG_MAP_W, PKT_TYPE, DAC_INTF_TYPE)      dac_mon;
    syn_acortex_codec_adc_drvr#(REG_MAP_W,  PKT_TYPE, ADC_INTF_TYPE)    adc_drvr;
    syn_acortex_codec_adc_mon#(REG_MAP_W, PKT_TYPE, ADC_INTF_TYPE)      adc_mon;
    syn_acortex_codec_adc_seqr#(PKT_TYPE)                               adc_seqr;

    OVM_FILE  f;


    /*  Constructor */
    function new(string name  = "syn_acortex_codec_agent", ovm_component parent = null);
      super.new(name, parent);
    endfunction: new


    /*  Build */
    function void build();
      super.build();

      f = $fopen({"./logs/",get_full_name(),".log"},  "w");

      set_report_default_file(f);
      set_report_severity_action(OVM_INFO,  OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_WARNING, OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_ERROR,  OVM_COUNT | OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_FATAL,  OVM_EXIT | OVM_DISPLAY | OVM_LOG);

      ovm_report_info(get_name(),"Start of build ",OVM_LOW);

      //Build Seqr, Drvr, Mon, Sb objects using Factory
      i2c_slave = syn_acortex_codec_i2c_slave#(REG_MAP_W,I2C_DATA_W,I2C_INTF_TYPE)::type_id::create("i2c_slave",  this);
      dac_mon   = syn_acortex_codec_dac_mon#(REG_MAP_W,PKT_TYPE,DAC_INTF_TYPE)::type_id::create("dac_mon",  this);
      adc_drvr  = syn_acortex_codec_adc_drvr#(REG_MAP_W,PKT_TYPE,ADC_INTF_TYPE)::type_id::create("adc_drvr",  this);
      adc_mon   = syn_acortex_codec_adc_mon#(REG_MAP_W,PKT_TYPE,ADC_INTF_TYPE)::type_id::create("adc_mon",  this);
      adc_seqr  = syn_acortex_codec_adc_seqr#(PKT_TYPE)::type_id::create("adc_seqr",  this);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*  Connect */
    function void connect();
      super.connect();

      ovm_report_info(get_name(),"START of connect ",OVM_LOW);

        //Make port connections

      ovm_report_info(get_name(),"END of connect ",OVM_LOW);
    endfunction


    /*  Disable Agent */
    function  void  disable_agent();

      i2c_slave.enable  = 0;
      dac_mon.enable    = 0;
      adc_drvr.enable   = 0;
      adc_mon.enable    = 0;
      adc_seqr.enable   = 0;

      ovm_report_info(get_name(),"Disabled myself & kids ...",OVM_LOW);
    endfunction : disable_agent



  endclass  : syn_acortex_codec_agent

`endif
