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
 -- Component Name    : syn_acortex_codec_i2c_slave
 -- Author            : mammenx 
 -- Function          : This class will act as an I2C slave & respond to 
                        I2C read/write transactions.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_ACORTEX_CODEC_I2C_SLAVE
`define __SYN_ACORTEX_CODEC_I2C_SLAVE

  class syn_acortex_codec_i2c_slave #(parameter REG_MAP_W = 9,
                                      parameter DATA_W    = 16,
                                      type  INTF_TYPE = virtual syn_wm8731_intf.TB_I2C
                                    ) extends ovm_component;

    bit enable;

    OVM_FILE  f;

    INTF_TYPE intf;

    bit [7:0] dev_addr;

    /*  Register Map to hold DAC registers  */
    syn_reg_map#(REG_MAP_W)   reg_map;  //each register is 9b

    /*  Register with factory */
    `ovm_component_param_utils_begin(syn_acortex_codec_i2c_slave#(REG_MAP_W,DATA_W,INTF_TYPE))
      `ovm_field_int(enable,  OVM_ALL_ON);
      `ovm_field_int(dev_addr,  OVM_ALL_ON);
    `ovm_component_utils_end

    function new(string name  = "syn_acortex_codec_i2c_slave", ovm_component parent = null);
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
      dev_addr  = 'h34;

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
      bit[DATA_W-1:0] data;

      ovm_report_info({get_name(),"[run]"},"Start of run ",OVM_LOW);

      if(enable)
      begin
        intf.i2c_intf.sda_tb = 'bz;

        forever
        begin
          ovm_report_info({get_name(),"[run]"},"Waiting for <Start> ...",OVM_LOW);

          @(negedge intf.i2c_intf.sda);
          @(negedge intf.i2c_intf.scl);

          ovm_report_info({get_name(),"[run]"},"<Start> detected ...",OVM_LOW);

          addr  = 'd0;

          repeat(7)
          begin
            @(posedge intf.i2c_intf.scl);
            #1;

            addr  = (addr <<  1)  + intf.i2c_intf.sda; //sample address bits
          end

          ovm_report_info({get_name(),"[run]"},$psprintf("Got address : 0x%x",addr),OVM_LOW);

          @(posedge intf.i2c_intf.scl);
          #1;

          rd_n_wr = intf.i2c_intf.sda;   //sample RD/nWR bit

          ovm_report_info({get_name(),"[run]"},$psprintf("Got Read/nWr : 0x%x",rd_n_wr),OVM_LOW);

          @(posedge intf.i2c_intf.scl)
          #2;

          if({addr,rd_n_wr}  ==  dev_addr)  //Device address
          begin
            ovm_report_info({get_name(),"[run]"},$psprintf("Driving ACK"),OVM_LOW);
            intf.i2c_intf.sda_tb = 0;

            @(negedge intf.i2c_intf.scl);
            intf.i2c_intf.sda_tb = 'bz;
          end
          else
          begin
            ovm_report_error({get_name(),"[run]"},$psprintf("Driving NACK"),OVM_LOW);
            intf.i2c_intf.sda_tb = 1;

            @(negedge intf.i2c_intf.scl);
            intf.i2c_intf.sda_tb = 'bz;

            @(posedge intf.i2c_intf.scl);
            @(posedge intf.i2c_intf.sda);
            ovm_report_info({get_name(),"[run]"},$psprintf("<STOP> detected ...\n\n\n"),OVM_LOW);

            continue;
          end

          data  = 'd0;

          repeat(DATA_W/8)
          begin
            repeat(8)
            begin
              @(posedge intf.i2c_intf.scl);
              #1;

              data  = (data <<  1)  + intf.i2c_intf.sda;
            end

            @(posedge intf.i2c_intf.scl);
            #2;

            ovm_report_info({get_name(),"[run]"},$psprintf("Driving ACK"),OVM_LOW);
            intf.i2c_intf.sda_tb = 0;

            @(negedge intf.i2c_intf.scl);
            intf.i2c_intf.sda_tb = 'bz;
          end

          @(posedge intf.i2c_intf.scl);
          @(posedge intf.i2c_intf.sda);
          ovm_report_info({get_name(),"[run]"},$psprintf("<STOP> detected ...\n\n\n"),OVM_LOW);

          if(reg_map.chk_addr_exist(data[DATA_W-1:REG_MAP_W]) ==  syn_reg_map#(REG_MAP_W)::SUCCESS)
          begin
            reg_map.set_reg(data[DATA_W-1:REG_MAP_W], data[REG_MAP_W-1:0]);
          end
          else
          begin
            ovm_report_error({get_name(),"[run]"},$psprintf("Invalid DAC address 0x%x",data[DATA_W-1:REG_MAP_W]),OVM_LOW);
          end
        end
      end
      else
      begin
        ovm_report_info({get_name(),"[run]"},"syn_acortex_codec_i2c_slave is disabled",OVM_LOW);
        ovm_report_info({get_name(),"[run]"},"Shutting down .....",OVM_LOW);
      end

    endtask : run

  endclass  : syn_acortex_codec_i2c_slave

`endif
