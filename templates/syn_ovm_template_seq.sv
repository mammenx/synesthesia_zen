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
 -- Sequence Name     : <seq_name>
 -- Author            : 
 -- Function          :
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

`ifndef __<seq_name>
`define __<seq_name>

  class <seq_name>   #(
                        type  PKT_TYPE  = ,
                        type  SEQR_TYPE =
                     ) extends ovm_sequence  #(PKT_TYPE);

    /*  Adding the parameterized sequence to the registery  */
    typedef <seq_name>#(PKT_TYPE,SEQR_TYPE) this_type;
    typedef ovm_object_registry#(this_type)type_id;

    /*  Linking with p_sequencer  */
    `ovm_declare_p_sequencer(SEQR_TYPE)


    /*  Constructor */
    function new(string name  = "<seq_name>");
      super.new(name);
    endfunction

    /*  Body of sequence  */
    task  body();
      p_sequencer.ovm_report_info(get_name(),"Start of <seq_name>",OVM_LOW);

    endtask : body


  endclass  : <seq_name>

`endif
