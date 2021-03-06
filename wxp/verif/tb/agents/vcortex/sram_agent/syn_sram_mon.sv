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
 -- Component Name    : syn_sram_mon
 -- Author            : mammenx
 -- Function          : This component monitors the SRAM interface and
                        sends RW xtns to scoreboard.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_SRAM_MON
`define __SYN_SRAM_MON

  class syn_sram_mon  #(parameter DATA_W  = 16,
                        parameter ADDR_W  = 18,
                        type  PKT_TYPE    = syn_lb_seq_item,
                        type  INTF_TYPE   = virtual syn_sram_mem_intf.TB
                      ) extends ovm_component;

    INTF_TYPE intf;

    ovm_analysis_port #(PKT_TYPE) Mon2Sb_port;

    OVM_FILE  f;

    PKT_TYPE  pkt;

    shortint  enable;

    /*  Register with factory */
    `ovm_component_param_utils_begin(syn_sram_mon#(DATA_W,ADDR_W,PKT_TYPE, INTF_TYPE))
      `ovm_field_int(enable,  OVM_ALL_ON);
    `ovm_component_utils_end


    /*  Constructor */
    function new( string name = "syn_sram_mon" , ovm_component parent = null) ;
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

      Mon2Sb_port = new("Mon2Sb_port", this);

      pkt = new();

      enable  = 1;  //Enabled by default; disable from test case

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    /*  Run */
    task run();
      /*  Check if the parameters are in sync!  */
      //  if(intf.SRAM_ADDR.size  !=  ADDR_W)
      //     ovm_report_fatal({get_name(),"[run]"},$psprintf("sram_addr_w(%d) does not match ADDR_W(%d) !!!",intf.SRAM_ADDR.size,ADDR_W),OVM_LOW);


      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      @(posedge intf.rst_il);

      if(enable)
      begin
        fork
          begin
            forever
            begin
              //Monitor logic
              //@(intf.SRAM_DQ, intf.SRAM_ADDR, intf.SRAM_LB_N, intf.SRAM_UB_N, intf.SRAM_CE_N, intf.SRAM_OE_N, intf.SRAM_WE_N);
              @(negedge intf.clk_ir iff intf.rst_il); //sample @mid of phase

              #4ns;

              if(!intf.SRAM_OE_N  &&  !intf.SRAM_CE_N) //read command
              begin
                pkt = new("sram_rd_seq_item");
                pkt.addr  = new[1];
                pkt.data  = new[1];

                pkt.lb_xtn  = READ;
                pkt.addr[0] = intf.SRAM_ADDR;
                pkt.data[0] = intf.SRAM_DI;

                //Send captured pkt to SB
                ovm_report_info({get_name(),"[run]"},$psprintf("Sending pkt to SB -\n%s", pkt.sprint()),OVM_LOW);
                Mon2Sb_port.write(pkt);
              end

              if(!intf.SRAM_WE_N  &&  !intf.SRAM_CE_N)  //write command
              begin
                pkt = new("sram_wr_seq_item");
                pkt.addr  = new[1];
                pkt.data  = new[1];

                pkt.lb_xtn  = WRITE;
                pkt.addr[0] = intf.SRAM_ADDR;
                pkt.data[0] = {DATA_W{1'b0}};

                if(~intf.SRAM_LB_N)
                begin
                  pkt.data[0][(DATA_W/2)-1:0] = intf.SRAM_DO[(DATA_W/2)-1:0];
                end

                if(~intf.SRAM_UB_N)
                begin
                  pkt.data[0][DATA_W-1:(DATA_W/2)] = intf.SRAM_DO[DATA_W-1:(DATA_W/2)];
                end

                //Send captured pkt to SB
                ovm_report_info({get_name(),"[run]"},$psprintf("Sending pkt to SB -\n%s", pkt.sprint()),OVM_LOW);
                Mon2Sb_port.write(pkt);
              end
            end
          end
        join
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_sram_mon  is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run


  endclass  : syn_sram_mon

`endif
