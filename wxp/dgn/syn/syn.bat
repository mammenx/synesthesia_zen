@echo off

SETLOCAL

set PRJ_NAME=syn_zen_fpga_top

echo  Starting Quartus project %PRJ_NAME%

quartus_map --read_settings_files=on --write_settings_files=off %PRJ_NAME% -c %PRJ_NAME%
quartus_fit --read_settings_files=off --write_settings_files=off %PRJ_NAME% -c %PRJ_NAME%
quartus_asm --read_settings_files=off --write_settings_files=off %PRJ_NAME% -c %PRJ_NAME%
quartus_sta %PRJ_NAME% -c %PRJ_NAME%

pause
