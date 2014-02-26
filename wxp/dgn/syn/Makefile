PRJ_NAME=syn_zen_fpga_top

clean:
	rm -rf *.rpt *.log *.summary *.done *.smsg
	rm -rf .qsys_edit
	rm -rf db
	rm -rf greybox_tmp
	rm -rf incremental_db

archive:
	rm -rf *.qar *.qarlog
	echo "Archiving Quartus Project $(PRJ_NAME)"
	quartus_sh --archive $(PRJ_NAME)

syn:
	echo "Starting Quartus project $(PRJ_NAME)"
	quartus_map --read_settings_files=on --write_settings_files=off $(PRJ_NAME) -c $(PRJ_NAME)
	quartus_fit --read_settings_files=off --write_settings_files=off $(PRJ_NAME) -c $(PRJ_NAME)
	quartus_asm --read_settings_files=off --write_settings_files=off $(PRJ_NAME) -c $(PRJ_NAME)
	quartus_sta $(PRJ_NAME) -c $(PRJ_NAME)
	echo "Quartus Done ..."
