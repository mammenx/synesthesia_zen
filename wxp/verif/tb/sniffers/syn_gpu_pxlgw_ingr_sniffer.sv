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
 -- Component Name    : syn_gpu_pxlgw_ingr_sniffer
 -- Author            : mammenx
 -- Function          : This component captures all pixel transactions
                        reaching the input of pxl_gw module & sends to
                        fb_sb.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_GPU_PXLGW_INGR_SNIFFER
`define __SYN_GPU_PXLGW_INGR_SNIFFER

  class syn_gpu_pxlgw_ingr_sniffer  #(type  PKT_TYPE  = syn_gpu_pxl_xfr_seq_item,
                                      type  INTF_TYPE = virtual syn_pxl_xfr_tb_intf
                                    ) extends ovm_component;

    INTF_TYPE intf;

    ovm_analysis_port #(PKT_TYPE) Sniffer2Sb_port;

    OVM_FILE  f;

    PKT_TYPE  pkt;

    shortint  enable;

    /*  Register with factory */
    `ovm_component_param_utils(syn_gpu_pxlgw_ingr_sniffer#(PKT_TYPE, INTF_TYPE))


    /*  Constructor */
    function new( string name = "syn_gpu_pxlgw_ingr_sniffer" , ovm_component parent = null) ;
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

      pkt = new();

      enable  = 1;  //Enabled by default; disable from test case

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    /*  Run */
    task run();

      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      //wait for reset
      @(posedge intf.rst_il);

      if(enable)
      begin
        forever
        begin
          //Monitor logic
          ovm_report_info({get_name(),"[run]"},"Sniffing for scent ...",OVM_LOW);
          @(posedge intf.clk_ir iff ((intf.cb.pxl_rd_valid | intf.cb.pxl_wr_valid) & intf.rst_il));

          pkt = new();

          if(intf.cb.pxl_wr_valid)
            pkt.xtn   = PXL_WRITE;
          else
            pkt.xtn   = PXL_READ;

          pkt.pxl   = intf.cb.pxl;
          $cast(pkt.posx, intf.cb.posx);
          $cast(pkt.posy, intf.cb.posy);

          //Send captured pkt to SB
          ovm_report_info({get_name(),"[run]"},$psprintf("Sending pkt to SB -\n%s", pkt.sprint()),OVM_LOW);
          Sniffer2Sb_port.write(pkt);
        end
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_gpu_pxlgw_ingr_sniffer  is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run


  endclass  : syn_gpu_pxlgw_ingr_sniffer

`endif
