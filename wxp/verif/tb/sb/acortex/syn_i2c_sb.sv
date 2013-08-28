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
 -- Component Name    : syn_i2c_sb
 -- Author            : mammenx
 -- Function          : This scoreboard checks if the I2C transactions
                        received by I2C monitor are the same as that
                        initiated by local bus.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_I2C_SB
`define __SYN_I2C_SB

//Implicit port declarations
`ovm_analysis_imp_decl(_i2c_pkt)
`ovm_analysis_imp_decl(_lb_pkt)

  class syn_i2c_sb  #(parameter I2C_DATA_W= 16,
                      type  SENT_PKT_TYPE = syn_lb_seq_item,
                      type  RCVD_PKT_TYPE = syn_lb_seq_item
                    ) extends ovm_scoreboard;

    `include  "syn_acortex_reg_map.sv"
 

    /*  Register with Factory */
    `ovm_component_param_utils(syn_i2c_sb#(SENT_PKT_TYPE, RCVD_PKT_TYPE))

    //Queue to hold the sent pkts, till rcvd pkts come
    RCVD_PKT_TYPE sent_que[$];
    RCVD_PKT_TYPE rcvd_que[$];

    //Ports
    ovm_analysis_imp_lb_pkt #(SENT_PKT_TYPE,syn_i2c_sb)   Mon_lb_2Sb_port;
    ovm_analysis_imp_i2c_pkt #(RCVD_PKT_TYPE,syn_i2c_sb)  Mon_i2c_2Sb_port;

    OVM_FILE  f;

    bit [6:0]             i2c_addr;
    bit                   i2c_rd_n_wr;
    bit [I2C_DATA_W-1:0]  i2c_data;


    /*  Constructor */
    function new(string name = "syn_i2c_sb", ovm_component parent);
      super.new(name, parent);
    endfunction : new


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

      Mon_lb_2Sb_port = new("Mon_lb_2Sb_port", this);
      Mon_i2c_2Sb_port = new("Mon_i2c_2Sb_port", this);


      ovm_report_info(get_name(),"End of build ",OVM_LOW);
    endfunction


    /*
      * Write LB Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_lb_pkt]Mon_lb_2Sb_port
    */
    virtual function void write_lb_pkt(input SENT_PKT_TYPE  pkt);
      RCVD_PKT_TYPE i2c_pkt;

      ovm_report_info({get_name(),"[write_lb_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      if((pkt.lb_xtn  ==  WRITE)  ||  (pkt.lb_xtn ==  BURST_WRITE))
      begin
        foreach(pkt.addr[i])
        begin
          if(pkt.addr[i]  ==  {ACORTEX_I2CM_CODE,ACORTEX_I2CM_ADDR_REG_ADDR})
          begin
            $cast({i2c_addr,i2c_rd_n_wr}, pkt.data[i]);
            ovm_report_info({get_name(),"[write_lb_pkt]"},$psprintf("Updated i2c_addr[0x%x], i2c_rd_n_wr[0x%x]",i2c_addr,i2c_rd_n_wr),OVM_LOW);
          end
          else if(pkt.addr[i] ==  ACORTEX_I2CM_DATA_REG_ADDR)
          begin
            $cast(i2c_data, pkt.data[i]);
            ovm_report_info({get_name(),"[write_lb_pkt]"},$psprintf("Updated i2c_data[0x%x]",i2c_data),OVM_LOW);
          end
          else if(pkt.addr[i] ==  ACORTEX_I2CM_STATUS_REG_ADDR)
          begin
            i2c_pkt = new();
            i2c_pkt.addr  = new[1];
            i2c_pkt.data  = new[I2C_DATA_W/8];

            $cast(i2c_pkt.addr[0], i2c_addr);

            foreach(i2c_pkt.data[i])
            begin
              i2c_pkt.data[i] = (i2c_data >>  (I2C_DATA_W - ((i+1)*8)))  & 8'hff;
            end

            if(i2c_rd_n_wr)
              i2c_pkt.lb_xtn  = READ;
            else
              i2c_pkt.lb_xtn  = WRITE;

            //Push packet into sent queue
            ovm_report_info({get_name(),"[write_lb_pkt]"},$psprintf("Adding pkt to sent_que[$]\n%s",i2c_pkt.sprint()),OVM_LOW);
            sent_que.push_back(i2c_pkt);
          end
        end
      end

      ovm_report_info({get_name(),"[write_lb_pkt]"},$psprintf("There are %d items in sent_que[$]",sent_que.size()),OVM_LOW);
    endfunction : write_lb_pkt


    /*
      * Write I2C Pkt
      * This function will be called each time a pkt is written into [ovm_analysis_imp_i2c_pkt]Mon_i2c_2Sb_port
    */
    virtual function void write_i2c_pkt(input RCVD_PKT_TYPE pkt);
      ovm_report_info({get_name(),"[write_i2c_pkt]"},$psprintf("Received pkt\n%s",pkt.sprint()),OVM_LOW);

      //Push packet into rcvd queue
      rcvd_que.push_back(pkt);

      ovm_report_info({get_name(),"[write_i2c_pkt]"},$psprintf("There are %d items in rcvd_que[$]",rcvd_que.size()),OVM_LOW);
    endfunction : write_i2c_pkt


    /*  Run */
    task run();
      RCVD_PKT_TYPE expctd_pkt,actual_pkt;
      ovm_report_info({get_name(),"[run]"},"Start of run",OVM_LOW);

      forever
      begin
        //Wait for items to arrive in sent & rcvd queues
        ovm_report_info({get_name(),"[run]"},"Waiting on queues ...",OVM_LOW);
        while(sent_que.size() &&  rcvd_que.size())  #1;

        expctd_pkt  = sent_que.pop_front();
        actual_pkt  = rcvd_que.pop_front();

        if(expctd_pkt.check(actual_pkt))
          ovm_report_info({get_name(),"[run]"},"I2C Transaction is correct",OVM_LOW);
        else
          ovm_report_error({get_name(),"[run]"},"I2C Transaction is incorrect",OVM_LOW);
      end

    endtask : run


    /*  Report  */
    virtual function void report();
      ovm_report_info({get_type_name(),"[report]"},$psprintf("Report -\n%s", this.sprint()), OVM_LOW);
    endfunction : report

  endclass : syn_i2c_sb

`endif
