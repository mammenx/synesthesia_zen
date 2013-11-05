@echo off

SETLOCAL

set PRJ_NAME=syn_zen_fpga_top

del /f /q %PRJ_NAME%.qar
del /f /q %PRJ_NAME%.qarlog

echo  Archiving Quartus project %PRJ_NAME%

quartus_sh --archive %PRJ_NAME%
