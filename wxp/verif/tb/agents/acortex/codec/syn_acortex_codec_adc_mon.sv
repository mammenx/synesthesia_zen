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
 -- Component Name    : syn_acortex_codec_adc_mon
 -- Author            : mammenx 
 -- Function          : This class monitors the ADC line of the CODEC &
                        sends pcm packets to the scoreboard.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __ACORTEX_CODEC_ADC_MON
`define __ACORTEX_CODEC_ADC_MON

  class syn_acortex_codec_adc_mon   #(parameter REG_MAP_W = 9,
                                      type  PKT_TYPE  = syn_pcm_seq_item,
                                      type  INTF_TYPE = virtual syn_aud_codec_if.TB_ADC
                                    ) extends ovm_component  #(PKT_TYPE);

    INTF_TYPE intf;

    OVM_FILE  f;

    shortint  enable;

    ovm_analysis_port #(PKT_TYPE) Mon2Sb_port;

    /*  Register Map to hold DAC registers  */
    syn_reg_map#(REG_MAP_W)   reg_map;  //each register is 9b

    /*  Register with factory */
    `ovm_component_param_utils_begin(syn_acortex_codec_adc_mon#(REG_MAP_W,PKT_TYPE, INTF_TYPE))
      `ovm_field_int(enable,  OVM_ALL_ON);
    `ovm_component_utils_end

    function new( string name = "syn_acortex_codec_adc_mon" , ovm_component parent = null) ;
      super.new( name , parent );

      enable    = 1;  //by default enabled; disable from test case
    endfunction : new

    function  void  build();
      super.build();

      f = $fopen({"./logs/",get_full_name(),".log"},  "w");

      set_report_default_file(f);
      set_report_severity_action(OVM_INFO,  OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_WARNING, OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_ERROR,  OVM_COUNT | OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_FATAL,  OVM_EXIT | OVM_DISPLAY | OVM_LOG);

      ovm_report_info(get_name(),"Start of build ",OVM_LOW);

        Mon2Sb_port = new("Mon2Sb_port",  this);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    task run();
      PKT_TYPE  pkt;
      int bps;

      if(enable)
      begin
        ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

        @(posedge intf.sys_rst);  //wait for reset

        case(reg_map.get_field("iwl"))

          syn_reg_map#(REG_MAP_W)::FAIL_FIELD_N_EXIST : ovm_report_fatal({get_name(),"[run]"},$psprintf("Could not find field <iwl> !!!"),OVM_LOW);

          0 : bps = 16;
          3 : bps = 32;

          default : ovm_report_fatal({get_name(),"[run]"},$psprintf("IWL val : %d not supported !!!", reg_map.get_field("iwl")),OVM_LOW);

        endcase

        forever
        begin
          ovm_report_info({get_name(),"[run]"},"Waiting for ADC LRC pulse",OVM_LOW);
          @(posedge intf.adc_lrc);
          ovm_report_info({get_name(),"[run]"},"Detected ADC LRC pulse",OVM_LOW);

          pkt = new();
          pkt.pcm_data  = new[1];

          for(int i=bps;  i>0;  i--)
          begin
            @(negedge intf.dac_bclk);
            #12ns;

            pkt.pcm_data[0].lchnnl[i-1] = intf.adc_dat;
          end

          if(bps  ==  16)
          begin
            pkt.pcm_data[0].lchnnl[31:16] = {16{pkt.pcm_data[0].lchnnl[15]}};
          end

          ovm_report_info({get_name(),"[run]"},$psprintf("Received LChannel ADC data[0x%x]",pkt.pcm_data[0].lchnnl),OVM_LOW);

          for(int i=bps;  i>0;  i--)
          begin
            @(negedge intf.dac_bclk);
            #12ns;

            pkt.pcm_data[0].rchnnl[i-1] = intf.adc_dat;
          end

          if(bps  ==  16)
          begin
            pkt.pcm_data[0].rchnnl[31:16] = {16{pkt.pcm_data[0].rchnnl[15]}};
          end

          ovm_report_info({get_name(),"[run]"},$psprintf("Received RChannel ADC data[0x%x]",pkt.pcm_data[0].rchnnl),OVM_LOW);
          #1;

          ovm_report_info({get_name(),"[run]"},$psprintf("Sending Packet to Scoreboard - \n%s\n\n\n", pkt.sprint()),OVM_LOW);
          Mon2Sb_port.write(pkt);
        end
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_acortex_codec_adc_mon is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run

  endclass  : syn_acortex_codec_adc_mon

`endif
