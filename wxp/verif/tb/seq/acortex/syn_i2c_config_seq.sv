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
 -- Sequence Name     : syn_i2c_config_seq
 -- Author            : mammenx
 -- Function          : This sequence configures the I2C_ADDR & I2C_DATA
                        fields in the i2c_master and triggers an I2C xtn.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __SYN_I2C_CONFIG_SEQ
`define __SYN_I2C_CONFIG_SEQ

  class syn_i2c_config_seq  #(
                              parameter I2C_DATA_W  = 16,
                              parameter type  PKT_TYPE  = syn_lb_seq_item,
                              parameter type  SEQR_TYPE = syn_lb_seqr#(PKT_TYPE)
                            ) extends ovm_sequence  #(PKT_TYPE);



    /*  Adding the parameterized sequence to the registery  */
    typedef syn_i2c_config_seq#(I2C_DATA_W,PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)

    `include  "syn_cortex_reg_map.sv"
    `include  "syn_acortex_reg_map.sv"


    `define I2C_ADDR      8'h34
    `define I2C_CLK_DIV   8'd100

    bit [I2C_DATA_W-1:0]  i2c_data;
    bit                   poll_en;

    /*  Constructor */
    function new(string name  = "syn_i2c_config_seq");
      super.new(name);

      i2c_data  = 'd0;
      poll_en   =   1;
    endfunction

    /*  Body of sequence  */
    task  body();
      PKT_TYPE  pkt,rsp;
      int i;

      p_sequencer.ovm_report_info(get_name(),"Start of syn_i2c_config_seq",OVM_LOW);

      $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("I2C Config Seq")));

      start_item(pkt);  //start_item has wait_for_grant()
      
      pkt.addr  = new[4];
      pkt.data  = new[4];
      pkt.lb_xtn= BURST_WRITE;

      $cast(pkt.addr[0],  {ACORTEX_BLK,ACORTEX_I2CM_CODE,ACORTEX_I2CM_ADDR_REG_ADDR});
      pkt.data[0] = `I2C_ADDR;

      $cast(pkt.addr[1],  {ACORTEX_BLK,ACORTEX_I2CM_CODE,ACORTEX_I2CM_DATA_REG_ADDR});
      pkt.data[1] = i2c_data;

      $cast(pkt.addr[2],  {ACORTEX_BLK,ACORTEX_I2CM_CODE,ACORTEX_I2CM_CLK_DIV_REG_ADDR});
      pkt.data[2] = `I2C_CLK_DIV;

      $cast(pkt.addr[3],  {ACORTEX_BLK,ACORTEX_I2CM_CODE,ACORTEX_I2CM_STATUS_REG_ADDR});
      pkt.data[3] = 'd0;

      p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);


      finish_item(pkt);

      #1;

      if(poll_en)
      begin
        p_sequencer.ovm_report_info(get_name(),"Start of Polling ...",OVM_LOW);
        i = 0;

        do
        begin
          #1us;

          $cast(pkt,create_item(PKT_TYPE::get_type(),m_sequencer,$psprintf("I2C Poll Seq[%1d]",i)));

          start_item(pkt);  //start_item has wait_for_grant()
          
          pkt.addr  = new[1];
          pkt.data  = new[1];
          pkt.lb_xtn= READ;

          $cast(pkt.addr[0],  {ACORTEX_BLK,ACORTEX_I2CM_CODE,ACORTEX_I2CM_STATUS_REG_ADDR});
          pkt.data[0] = $random;

          p_sequencer.ovm_report_info(get_name(),$psprintf("Generated pkt - \n%s", pkt.sprint()),OVM_LOW);

          finish_item(pkt);

          get_response(rsp);  //wait for response

          p_sequencer.ovm_report_info(get_name(),$psprintf("Got Response pkt - \n%s", rsp.sprint()),OVM_LOW);

          i++;
        end
        while(rsp.data[0] & 'h1); //while I2C driver is busy
      end


    endtask : body


  endclass  : syn_i2c_config_seq

`endif
