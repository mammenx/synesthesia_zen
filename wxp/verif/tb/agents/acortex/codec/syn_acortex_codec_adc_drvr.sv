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
 -- Component Name    : syn_acortex_codec_adc_drvr
 -- Author            : mammenx 
 -- Function          : This class drives ADC data from CODEC to DUT.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __ACORTEX_CODEC_ADC_DRVR
`define __ACORTEX_CODEC_ADC_DRVR

  class syn_acortex_codec_adc_drvr  #(parameter REG_MAP_W = 9,
                                      type  PKT_TYPE  = syn_pcm_seq_item,
                                      type  INTF_TYPE = virtual syn_aud_codec_if.TB_ADC
                                    ) extends ovm_driver  #(PKT_TYPE);

    INTF_TYPE intf;

    OVM_FILE  f;

    shortint  enable;

    /*  Register Map to hold DAC registers  */
    syn_reg_map#(REG_MAP_W)   reg_map;  //each register is 9b

    /*  Register with factory */
    `ovm_component_param_utils_begin(syn_acortex_codec_adc_drvr#(REG_MAP_W,PKT_TYPE, INTF_TYPE))
      `ovm_field_int(enable,  OVM_ALL_ON);
    `ovm_component_utils_end

    function new( string name = "syn_acortex_codec_adc_drvr" , ovm_component parent = null) ;
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


      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    task run();
      PKT_TYPE  pkt;

      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      drive_rst();

      @(posedge intf.rst_il);  //wait for reset

      if(enable)
      begin
        forever
        begin
          ovm_report_info({get_name(),"[run]"},"Waiting for seq_item",OVM_LOW);
          seq_item_port.get_next_item(pkt);

          ovm_report_info({get_name(),"[run]"},$psprintf("Got seq_item - \n%s",pkt.sprint()),OVM_LOW);

          drive(pkt);

          seq_item_port.item_done();
        end
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_acortex_codec_adc_drvr is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run


    task  drive(PKT_TYPE  pkt);
      bit [31:0]  ldata,rdata;
      int bps;

      ovm_report_info({get_name(),"[drive]"},"Start of drive ",OVM_LOW);

      case(reg_map.get_field("iwl"))

        syn_reg_map#(REG_MAP_W)::FAIL_FIELD_N_EXIST : ovm_report_fatal({get_name(),"[run]"},$psprintf("Could not find field <iwl> !!!"),OVM_LOW);

        0 : bps = 16;
        3 : bps = 32;

        default : ovm_report_fatal({get_name(),"[run]"},$psprintf("IWL val : %d not supported !!!", reg_map.get_field("iwl")),OVM_LOW);

      endcase

      //foreach(pkt.pcm_data[i])
      for(int i=0; i<pkt.pcm_data.size; i++)
      begin
        $cast(ldata,  pkt.pcm_data[i].lchnnl);
        $cast(rdata,  pkt.pcm_data[i].rchnnl);

        @(posedge intf.adc_lrc);
        //@(negedge intf.adc_lrc);
        ovm_report_info({get_name(),"[drive]"},"Detected ADC LRC pulse",OVM_LOW);

        for(int i=bps;  i>0;  i--)
        begin
          @(negedge intf.bclk);
          #10ns;  //propagation delay given in spec

          intf.adc_dat  <=  ldata[i-1];
        end

        ovm_report_info({get_name(),"[drive]"},$psprintf("Driven LChannel ADC data[%1d]",i),OVM_LOW);

        for(int i=bps;  i>0;  i--)
        begin
          @(negedge intf.bclk);
          #10ns;  //propagation delay given in spec

          intf.adc_dat  <=  rdata[i-1];
        end

        ovm_report_info({get_name(),"[drive]"},$psprintf("Driven RChannel ADC data[%1d]",i),OVM_LOW);
      end


      ovm_report_info({get_name(),"[drive]"},"End of drive ",OVM_LOW);
    endtask : drive


    task  drive_rst();
      ovm_report_info({get_name(),"[drive_rst]"},"Start of drive_rst ",OVM_LOW);

      intf.adc_dat <=  0;

      ovm_report_info({get_name(),"[drive_rst]"},"End of drive_rst ",OVM_LOW);
    endtask : drive_rst

  endclass  : syn_acortex_codec_adc_drvr

`endif
