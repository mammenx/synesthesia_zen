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
 -- Component Name    : syn_but_sniffer
 -- Author            : mammenx
 -- Function          : This component captures all transactions to & from
                        the Butterfy module.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_BUT_SNIFFER
`define __SYN_BUT_SNIFFER

  class syn_but_sniffer  #(type  PKT_TYPE  = syn_but_seq_item,
                           type  INTF_TYPE = virtual syn_but_intf
                               ) extends ovm_component;

    INTF_TYPE intf;

    ovm_analysis_port #(PKT_TYPE) SnifferIngr2Sb_port;
    ovm_analysis_port #(PKT_TYPE) SnifferEgr2Sb_port;

    OVM_FILE  f;

    shortint  enable;

    /*  Register with factory */
    `ovm_component_param_utils(syn_but_sniffer#(PKT_TYPE, INTF_TYPE))


    /*  Constructor */
    function new( string name = "syn_but_sniffer" , ovm_component parent = null) ;
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

      SnifferIngr2Sb_port = new("SnifferIngr2Sb_port", this);
      SnifferEgr2Sb_port  = new("SnifferEgr2Sb_port", this);

      enable  = 1;  //Enabled by default; disable from test case

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    /*  Run */
    task run();
      PKT_TYPE  ingr_pkt,egr_pkt;

      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      //wait for reset
      @(posedge intf.rst_il);

      if(enable)
      begin
        fork
          begin
            forever //Ingr monitor logic
            begin
              @(posedge intf.clk_ir);
              #1;

              if(intf.sample_rdy)
              begin
                ingr_pkt = new();

                $cast(ingr_pkt.sample_a, intf.sample_a);
                $cast(ingr_pkt.sample_b, intf.sample_b);
                $cast(ingr_pkt.twdl,     intf.twdl);

                ovm_report_info({get_name(),"[run-ingr]"},$psprintf("Got sample_a{0x%x,0x%x} sample_b{0x%x,0x%x} twdl{0x%x,0x%x}",ingr_pkt.sample_a.re,ingr_pkt.sample_a.im,ingr_pkt.sample_b.re,ingr_pkt.sample_b.im,ingr_pkt.twdl.re,ingr_pkt.twdl.im),OVM_LOW);

                SnifferIngr2Sb_port.write(ingr_pkt);
              end
            end
          end

          begin
            forever //Egr monitor logic
            begin
              @(posedge intf.clk_ir);
              #1;

              if(intf.res_rdy)
              begin
                egr_pkt = new();

                $cast(egr_pkt.sample_a, intf.res);
                egr_pkt.sample_b.re = 0;
                egr_pkt.sample_b.im = 0;
                egr_pkt.twdl.re = 0;
                egr_pkt.twdl.im = 0;

                ovm_report_info({get_name(),"[run-egr]"},$psprintf("Got res{0x%x,0x%x}",egr_pkt.sample_a.re,egr_pkt.sample_a.im),OVM_LOW);

                SnifferEgr2Sb_port.write(egr_pkt);
              end
            end
          end
        join
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_but_sniffer  is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run


  endclass  : syn_but_sniffer

`endif
