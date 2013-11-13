/*
    ChibiOS/RT - Copyright (C) 2006,2007,2008,2009,2010,2011 Giovanni Di Sirio.

    This file is part of ChibiOS/RT.

    ChibiOS/RT is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    ChibiOS/RT is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

                                      ---

    A special exception to the GPL can be applied should you wish to distribute
    a combined work that includes ChibiOS/RT, without being obliged to provide
    the source code for any proprietary components. See the file exception.txt
    for full details of how and when the exception can be applied.
*/

/**
 * @file    NIOSII/chcore.c
 * @brief   NIOSII architecture port code.
 *
 * @addtogroup NIOSII_CORE
 * @{
 */

#include "ch.h"

/**
 * @brief   Halts the system.
 * @details This function is invoked by the operating system when an
 *          unrecoverable error is detected (as example because a programming
 *          error in the application code that triggers an assertion while in
 *          debug mode).
 * @note    The function is declared as a weak symbol, it is possible to
 *          redefine it in your application code.
 */
#if !defined(__DOXYGEN__)
__attribute__((weak))
#endif
void port_halt (void) 
{
   port_disable();
   while (TRUE) 
   {
   }  
}

/*
 * ChibiOS time tick, called by the Nios
 * hal.sys_clk_timer.
 */
CH_IRQ_HANDLER (port_time_tick)
{
   CH_IRQ_PROLOGUE();

   chSysLockFromIsr();
   chSysTimerHandlerI();
   chSysUnlockFromIsr();

   CH_IRQ_EPILOGUE();
} /* port_time_tick */


/** @} */
