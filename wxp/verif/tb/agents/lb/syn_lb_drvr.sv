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
 -- Component Name    : syn_lb_drvr
 -- Author            : mammenx 
 -- Function          : This is a generic driver that drives LB xtns to DUT.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_LB_DRVR
`define __SYN_LB_DRVR

  class syn_lb_drvr #(parameter DATA_W  = 32,
                      parameter ADDR_W  = 16,
                      type  PKT_TYPE    = syn_lb_seq_item,
                      type  INTF_TYPE   = virtual syn_lb_intf
                    ) extends ovm_driver  #(PKT_TYPE,PKT_TYPE); //request, response

    INTF_TYPE intf;

    OVM_FILE  f;

    shortint  enable;


    /*  Register with factory */
    `ovm_component_param_utils_begin(syn_lb_drvr#(DATA_W,ADDR_W,PKT_TYPE, INTF_TYPE))
      `ovm_field_int(enable,  OVM_ALL_ON);
    `ovm_component_utils_end


    /*  Constructor */
    function new( string name = "syn_lb_drvr" , ovm_component parent = null) ;
      super.new( name , parent );

      enable    = 1;  //by default enabled; disable from test case
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


      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction : build


    /*  Run */
    task run();
      PKT_TYPE  pkt = new();
      PKT_TYPE  pkt_rsp;

      /*  Check if the parameters are in sync!  */
      //  if(intf.addr.size !=  ADDR_W)
      //     ovm_report_fatal({get_name(),"[run]"},$psprintf("Intf addr_w(%d) does not match ADDR_W(%d) !!!",intf.addr.size,ADDR_W),OVM_LOW);

      //  if(intf.wr_data.size !=  DATA_W)
      //     ovm_report_fatal({get_name(),"[run]"},$psprintf("Intf wr_data_w(%d) does not match DATA_W(%d) !!!",intf.wr_data.size,DATA_W),OVM_LOW);

      //  if(intf.rd_data.size !=  DATA_W)
      //     ovm_report_fatal({get_name(),"[run]"},$psprintf("Intf rd_data_w(%d) does not match DATA_W(%d) !!!",intf.rd_data.size,DATA_W),OVM_LOW);


      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      if(enable)
      begin
        //Wait for reset  ...
        drive_rst();

        @(posedge intf.rst_il); //wait for reset to be lifted

        repeat(10)  @(intf.cb); //wait for 10 clocks

        forever
        begin
          ovm_report_info({get_name(),"[run]"},"Waiting for seq_item",OVM_LOW);
          seq_item_port.get_next_item(pkt);

          ovm_report_info({get_name(),"[run]"},$psprintf("Got seq_item - \n%s",pkt.sprint()),OVM_LOW);

          drive(pkt);

          //Send back response
          if((pkt.lb_xtn  ==  READ) ||  (pkt.lb_xtn ==  BURST_READ))
          begin
            pkt_rsp = new();

            pkt_rsp.lb_xtn  = pkt.lb_xtn;
            pkt_rsp.addr    = new[pkt.addr.size];
            pkt_rsp.data    = new[pkt.data.size];
            foreach(pkt.addr[i])
            begin
              pkt_rsp.addr[i] = pkt.addr[i];
              pkt_rsp.data[i] = pkt.data[i];
            end

            pkt_rsp.set_id_info(pkt);
            #1;
            seq_item_port.put_response(pkt_rsp);
          end

          seq_item_port.item_done();
        end
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_lb_drvr is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end
    endtask : run


    /*  Drive */
    task  drive(PKT_TYPE  pkt);
      bit read_n_write;
      int num = 0;

      ovm_report_info({get_name(),"[drive]"},"Start of drive ",OVM_LOW);

      if((pkt.lb_xtn  ==  READ) ||  (pkt.lb_xtn ==  BURST_READ))
      begin
        read_n_write  = 1;
      end
      else  //if WRITE
      begin
        read_n_write  = 0;
      end

      @(intf.cb);

      fork
        begin
          foreach(pkt.addr[i])
          begin
            intf.cb.rd_en          <=  read_n_write  ? 1 : 0;
            intf.cb.wr_en          <=  read_n_write  ? 0 : 1;
            intf.cb.addr           <=  pkt.addr[i]  & 'hffff;
            intf.cb.wr_data        <=  pkt.data[i];

            //ovm_report_info({get_name(),"[drive]"},$psprintf("Driving read_n_write[%1d] addr[%1d]",read_n_write,num),OVM_LOW);
            //num++;

            //@(intf.cb);
            @(posedge intf.clk_ir);
          end

          intf.cb.wr_en     <=  0;
          intf.cb.rd_en     <=  0;

          //@(intf.cb);
          @(posedge intf.clk_ir);
        end

        begin
          if(read_n_write)
          begin
            foreach(pkt.addr[i])
            begin
              @(posedge intf.clk_ir iff intf.cb.rd_valid  ==  1); //wait for valid to be asserted

              pkt.data[i]          =  intf.cb.rd_data;  //sample data
            end
          end
          else
          begin
            #1;
          end
        end

      join  //join_all

      //@(intf.cb);
      @(posedge intf.clk_ir);

      ovm_report_info({get_name(),"[drive]"},"End of drive ",OVM_LOW);
    endtask : drive

    /*  Drive Reset */
    task  drive_rst;
      ovm_report_info({get_name(),"[drive_rst]"},"Start of drive_rst",OVM_LOW);

        intf.cb.rd_en    <= 0;
        intf.cb.wr_en    <= 0;
        intf.cb.addr     <= 0;
        intf.cb.wr_data  <= 0;


      ovm_report_info({get_name(),"[drive_rst]"},"End of drive_rst",OVM_LOW);
    endtask : drive_rst

  endclass  : syn_lb_drvr

`endif
