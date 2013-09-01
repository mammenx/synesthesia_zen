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
 -- Component Name    : syn_acortex_codec_i2c_mon
 -- Author            : mammenx 
 -- Function          : This class monitors the I2C interface & sends
                        packets to scoreboard.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_ACORTEX_CODEC_I2C_MON
`define __SYN_ACORTEX_CODEC_I2C_MON

  class syn_acortex_codec_i2c_mon   #(
                                      parameter DATA_W    = 16,
                                      type  PKT_TYPE  = syn_lb_seq_item,
                                      type  INTF_TYPE = virtual syn_wm8731_intf.TB_I2C
                                    ) extends ovm_component;

    bit enable;

    OVM_FILE  f;

    INTF_TYPE intf;

    ovm_analysis_port #(PKT_TYPE) Mon2Sb_port;

    /*  Register with factory */
    `ovm_component_param_utils_begin(syn_acortex_codec_i2c_mon#(DATA_W,PKT_TYPE,INTF_TYPE))
      `ovm_field_int(enable,  OVM_ALL_ON);
    `ovm_component_utils_end

    function new(string name  = "syn_acortex_codec_i2c_mon", ovm_component parent = null);
      super.new(name, parent);
    endfunction: new

    function void build();
      super.build();

      f = $fopen({"./logs/",get_full_name(),".log"},  "w");

      set_report_default_file(f);
      set_report_severity_action(OVM_INFO,  OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_WARNING, OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_ERROR,  OVM_COUNT | OVM_DISPLAY | OVM_LOG);
      set_report_severity_action(OVM_FATAL,  OVM_EXIT | OVM_DISPLAY | OVM_LOG);

      ovm_report_info(get_name(),"Start of build ",OVM_LOW);

      enable  = 1;

      Mon2Sb_port = new("Mon2Sb_port",  this);

      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    function void connect();
      super.connect();

      ovm_report_info(get_name(),"START of connect ",OVM_LOW);


      ovm_report_info(get_name(),"END of connect ",OVM_LOW);
    endfunction

    task  run();
      bit[6:0]  addr;
      bit       rd_n_wr;
      bit[7:0]  data;
      PKT_TYPE  pkt;

      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      if(enable)
      begin
        @(posedge intf.rst_il);

        forever
        begin
          ovm_report_info({get_name(),"[run]"},"Waiting for <Start> ...",OVM_LOW);

          @(negedge intf.sda);
          @(negedge intf.scl);

          ovm_report_info({get_name(),"[run]"},"<Start> detected ...",OVM_LOW);

          addr  = 'd0;
          pkt   = new();
          pkt.addr  = new[1];
          pkt.data  = new[DATA_W/8];  //in units of bytes

          repeat(7)
          begin
            @(posedge intf.scl);
            #1;

            addr  = (addr <<  1)  + intf.sda; //sample address bits
          end

          ovm_report_info({get_name(),"[run]"},$psprintf("Got address : 0x%x",addr),OVM_LOW);
          $cast(pkt.addr[0],  addr);

          @(posedge intf.scl);
          #1;

          rd_n_wr = intf.sda;   //sample RD/nWR bit

          ovm_report_info({get_name(),"[run]"},$psprintf("Got Read/nWr : 0x%x",rd_n_wr),OVM_LOW);

          if(rd_n_wr)
            pkt.lb_xtn  = READ;
          else
            pkt.lb_xtn  = WRITE;


          @(posedge intf.scl)
          #2;

          data  = 'd0;

          foreach(pkt.data[i])
          begin
            repeat(8)
            begin
              @(posedge intf.scl);
              #1;

              data  = (data <<  1)  + intf.sda;
            end

            $cast(pkt.data[i],  data);
            ovm_report_info({get_name(),"[run]"},$psprintf("Received data - 0x%x",pkt.data[i]),OVM_LOW);

            @(posedge intf.scl);
            #3;

            if(intf.sda)
            begin
              ovm_report_info({get_name(),"[run]"},$psprintf("NACK Detected"),OVM_LOW);
              break;
            end
            else
            begin
              ovm_report_info({get_name(),"[run]"},$psprintf("ACK Detected"),OVM_LOW);
            end

            @(negedge intf.scl);
          end

          @(posedge intf.scl);
          @(posedge intf.sda);
          ovm_report_info({get_name(),"[run]"},$psprintf("<STOP> detected ...\n\n\n"),OVM_LOW);
          #1;

          ovm_report_info({get_name(),"[run]"},$psprintf("Sending Packet to Scoreboard - \n%s\n\n\n", pkt.sprint()),OVM_LOW);
          Mon2Sb_port.write(pkt);
        end
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_acortex_codec_i2c_mon is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end

    endtask : run

  endclass  : syn_acortex_codec_i2c_mon

`endif
