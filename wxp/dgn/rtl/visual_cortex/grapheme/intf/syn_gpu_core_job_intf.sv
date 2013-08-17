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
 -- Interface Name    : syn_gpu_core_job_intf
 -- Author            : mammenx
 -- Function          : This interface encapsulates signals & structures
                        for triggering GPU jobs to different engines. The
                        status signals from different engines are also
                        included.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

interface syn_gpu_core_job_intf (input logic clk_ir, rst_il);

  import  syn_gpu_pkg::*;

  //Signals & Structures
  logic           euclid_job_start; //1->Start line/bezier draw job in euclid engine
  gpu_draw_job_t  euclid_job_data;  //Details of job
  logic           euclid_busy;      //1->Euclid engine is busy
  logic           euclid_job_done;  //1->Job is done

  logic           picasso_job_start; //1->Start fill job in picasso engine
  gpu_fill_job_t  picasso_job_data;  //Details of job
  logic           picasso_busy;      //1->Picasso engine is busy
  logic           picasso_job_done;  //1->Job is done


  //Modports
  modport master  (
                    output  euclid_job_start,
                    output  euclid_job_data,
                    input   euclid_busy,
                    input   euclid_job_done,

                    output  picasso_job_start,
                    output  picasso_job_data,
                    input   picasso_busy,
                    input   picasso_job_done
                  );

  modport euclid  (
                    input   euclid_job_start,
                    input   euclid_job_data,
                    output  euclid_busy,
                    output  euclid_job_done
                  );

  modport picasso  (
                    input   picasso_job_start,
                    input   picasso_job_data,
                    output  picasso_busy,
                    output  picasso_job_done
                  );


endinterface  //  syn_gpu_core_job_intf
