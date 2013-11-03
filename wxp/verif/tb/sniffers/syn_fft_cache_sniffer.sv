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
 -- Component Name    : syn_fft_cache_sniffer
 -- Author            : mammenx
 -- Function          : This component captures all Write transactions to
                        the FFT cache.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_FFT_CACHE_SNIFFER
`define __SYN_FFT_CACHE_SNIFFER

  class syn_fft_cache_sniffer  #(type  PKT_TYPE  = syn_fft_cache_seq_item,
                                 type  INTF_TYPE = virtual syn_fft_cache_intf
                               ) extends ovm_component;

    INTF_TYPE intf;

    ovm_analysis_port #(PKT_TYPE) Sniffer2Sb_port;

    OVM_FILE  f;

    shortint  enable;

    /*  Register with factory */
    `ovm_component_param_utils(syn_fft_cache_sniffer#(PKT_TYPE, INTF_TYPE))


    /*  Constructor */
    function new( string name = "syn_fft_cache_sniffer" , ovm_component parent = null) ;
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

      Sniffer2Sb_port = new("Sniffer2Sb_port", this);

      enable  = 1;  //Enabled by default; disable from test case

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    /*  Run */
    task run();
      PKT_TYPE  pkt;

      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      //wait for reset
      @(posedge intf.rst_il);

      if(enable)
      begin
        fork
          begin
            forever
            begin
              @(posedge intf.clk_ir);
              #1;

              if(intf.wr_en)
              begin
                pkt = new();

                $cast(pkt.addr,   intf.waddr);
                $cast(pkt.sample, intf.wr_sample);

                ovm_report_info({get_name(),"[run]"},$psprintf("Got sample{0x%x,0x%x} @ 0x%x",pkt.sample.re,pkt.sample.im,pkt.addr),OVM_LOW);

                Sniffer2Sb_port.write(pkt);
              end
            end
          end
        join
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_fft_cache_sniffer  is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run


  endclass  : syn_fft_cache_sniffer

`endif
