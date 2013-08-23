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
 -- Package Name      : syn_audio_pkg
 -- Author            : mammenx
 -- Description       : This package contains definitions of all Audio
                        related structures & types.
 --------------------------------------------------------------------------
*/

/*
 --------------------------------------------------------------------------

 -- $Header$
 

 -- $Log$

 --------------------------------------------------------------------------
*/

package syn_audio_pkg;

  //PCM Data structure
  typedef struct  packed  {
    logic [31:0]  lchnnl;
    logic [31:0]  rchnnl;
  } pcm_data_t;

  //Bits Per Sample data type
  typedef enum  logic {
                        BPS_16=0,
                        BPS_32
                      } bps_t;

  typedef enum  logic {
                        NORMAL=0,
                        CAPTURE
                      } acache_mode_t;

endpackage  //  syn_audio_pkg
