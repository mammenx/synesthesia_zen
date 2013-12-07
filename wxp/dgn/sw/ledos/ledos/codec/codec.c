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
 -- File Name         : codec.c
 -- Author            : mammenx
 -- Function          : 
 --------------------------------------------------------------------------
*/

#include "codec.h"
#include "alt_types.h"
#include "sys/alt_stdio.h"
#include "ch.h"

I2C_RES	codec_reset(){
	alt_u8 i;
/*
	codec_shadow_reg[0]	  =	0x97;
	codec_shadow_reg[1]   = 0x297;
	//codec_shadow_reg[0]	  =	0x17;
	//codec_shadow_reg[1]   = 0x217;
	//codec_shadow_reg[0]	  =	0x1f;
	//codec_shadow_reg[1]   = 0x21f;
	//codec_shadow_reg[2]   = 0x4e5;	//different from default
	//codec_shadow_reg[3]   = 0x6e5;	//different from default
	codec_shadow_reg[2]   = 0x4f9;
	codec_shadow_reg[3]   = 0x6f9;
	codec_shadow_reg[4]   = 0x80a;
	codec_shadow_reg[5]   = 0xa00;
	codec_shadow_reg[6]   = 0xcff;
	//codec_shadow_reg[7]   = 0xe0a;
	codec_shadow_reg[7]   = 0xe0f;	//different from default
	codec_shadow_reg[8]   = 0x1000;
	codec_shadow_reg[9]   = 0x1200;
	codec_shadow_reg[10]  = 0x1e00;
*/

	//All the below values are default values given in spec
	codec_shadow_reg[0]	  =	0x97;
	codec_shadow_reg[1]   = 0x297;
	codec_shadow_reg[2]   = 0x479;
	codec_shadow_reg[3]   = 0x679;
	codec_shadow_reg[4]   = 0x80a;
	codec_shadow_reg[5]   = 0xa08;
	codec_shadow_reg[6]   = 0xc9f;
	codec_shadow_reg[7]   = 0xe0a;
	codec_shadow_reg[8]   = 0x1000;
	codec_shadow_reg[9]   = 0x1200;
	codec_shadow_reg[10]  = 0x1e00;

	return	i2c_xtn_write16(CODEC_I2C_WRITE_ADDR, codec_shadow_reg[CODEC_RESET_IDX]);

	/*
	for(i=0; i<NO_OF_CODEC_REGS-1; i++){
		if(i2c_xtn_write16(CORTEX_MM_SL_BASE, CODEC_I2C_WRITE_ADDR, codec_shadow_reg[i])){
			return I2C_NACK_DETECTED;
		}
	}
	*/

	return I2C_OK;

}

I2C_RES	codec_config_reg(alt_u8 idx, alt_u8 offst, alt_u8 msk, alt_u8 val){
	codec_shadow_reg[idx]	&=	~(alt_u16)(msk	<<	offst);
	codec_shadow_reg[idx]	|=	(alt_u16)((val & msk)	<<	offst);

	return	i2c_xtn_write16(CODEC_I2C_WRITE_ADDR, codec_shadow_reg[idx]);
}

I2C_RES codec_init(BPS_T bps, CODEC_FS_T fs){

	disable_dac_drvr();
	disable_adc_drvr();

	if(codec_reset())	return I2C_NACK_DETECTED;

	chThdSleepMilliseconds(100);

	//Read Power On Sequence spec

	codec_shadow_reg[CODEC_POWER_DOWN_REG_IDX]	=	0xc10;
	if(i2c_xtn_write16(CODEC_I2C_WRITE_ADDR, codec_shadow_reg[CODEC_POWER_DOWN_REG_IDX]))	return I2C_NACK_DETECTED;


	codec_shadow_reg[CODEC_LEFT_LINE_IN_REG_IDX]=	0x17;
	if(i2c_xtn_write16(CODEC_I2C_WRITE_ADDR, codec_shadow_reg[CODEC_LEFT_LINE_IN_REG_IDX]))	return I2C_NACK_DETECTED;


	codec_shadow_reg[CODEC_RIGHT_LINE_IN_REG_IDX]=	0x217;
	if(i2c_xtn_write16(CODEC_I2C_WRITE_ADDR, codec_shadow_reg[CODEC_RIGHT_LINE_IN_REG_IDX]))	return I2C_NACK_DETECTED;


	codec_shadow_reg[CODEC_LEFT_HP_OUT_REG_IDX]=	0x4f9;
	if(i2c_xtn_write16(CODEC_I2C_WRITE_ADDR, codec_shadow_reg[CODEC_LEFT_HP_OUT_REG_IDX]))	return I2C_NACK_DETECTED;


	codec_shadow_reg[CODEC_RIGHT_HP_OUT_REG_IDX]=	0x6f9;
	if(i2c_xtn_write16(CODEC_I2C_WRITE_ADDR, codec_shadow_reg[CODEC_RIGHT_HP_OUT_REG_IDX]))	return I2C_NACK_DETECTED;


	codec_shadow_reg[CODEC_DIGITAL_AUD_PATH_REG_IDX]=	0xa00;
	if(i2c_xtn_write16(CODEC_I2C_WRITE_ADDR, codec_shadow_reg[CODEC_DIGITAL_AUD_PATH_REG_IDX]))	return I2C_NACK_DETECTED;


	codec_shadow_reg[CODEC_DIGITAL_AUD_IF_FMT_REG_IDX]=	0xe0f;
	if(i2c_xtn_write16(CODEC_I2C_WRITE_ADDR, codec_shadow_reg[CODEC_DIGITAL_AUD_IF_FMT_REG_IDX]))	return I2C_NACK_DETECTED;


	//Misc
	if(codec_iwl_update(bps2iwl_lookup[bps]))	return I2C_NACK_DETECTED;

	if(codec_sr_update(fs2sr_lookup[fs]))	return I2C_NACK_DETECTED;


	codec_shadow_reg[CODEC_ACTIVE_CTRL_REG_IDX]=	0x1200;
	if(i2c_xtn_write16(CODEC_I2C_WRITE_ADDR, codec_shadow_reg[CODEC_ACTIVE_CTRL_REG_IDX]))	return I2C_NACK_DETECTED;


	codec_shadow_reg[CODEC_POWER_DOWN_REG_IDX]	=	0xc00;
	if(i2c_xtn_write16(CODEC_I2C_WRITE_ADDR, codec_shadow_reg[CODEC_POWER_DOWN_REG_IDX]))	return I2C_NACK_DETECTED;


	//Keep WMDRVR in sync
	configure_wmdrvr_bps(bps);
	update_wmdrvr_fs_div(fs2div_lookup[fs]);

	//Debug ...
	//codec_dump_regs();

	alt_printf("[codec_init] Success\r\n");

	return I2C_OK;
}

I2C_RES codec_dsp_if_activate(){
	return codec_config_reg(CODEC_ACTIVE_IDX, CODEC_ACTIVE_OFFST, CODEC_ACTIVE_MSK, 0x1);
}

I2C_RES codec_dsp_if_inactivate(){
	return codec_config_reg(CODEC_ACTIVE_IDX, CODEC_ACTIVE_OFFST, CODEC_ACTIVE_MSK, 0x0);
}

I2C_RES codec_dac_activate(){
	//Referpg44 of WM8731 datasheet
	if(codec_config_reg(CODEC_DACPD_IDX, CODEC_DACPD_OFFST, CODEC_DACPD_MSK, 0x0))	return	I2C_NACK_DETECTED;

	//Refer pg26 of WM8731 datasheet
	if(codec_config_reg(CODEC_DAC_SEL_IDX, CODEC_DAC_SEL_OFFST, CODEC_DAC_SEL_MSK, 0x1))	return	I2C_NACK_DETECTED;

	if(codec_config_reg(CODEC_DAC_MU_IDX, CODEC_DAC_MU_OFFST, CODEC_DAC_MU_MSK, 0x0))	return	I2C_NACK_DETECTED;

	return I2C_OK;
}

I2C_RES codec_dac_inactivate(){

	if(codec_config_reg(CODEC_DAC_MU_IDX, CODEC_DAC_MU_OFFST, CODEC_DAC_MU_MSK, 0x1))	return	I2C_NACK_DETECTED;

	//Refer pg26 of WM8731 datasheet
	if(codec_config_reg(CODEC_DAC_SEL_IDX, CODEC_DAC_SEL_OFFST, CODEC_DAC_SEL_MSK, 0x0))	return	I2C_NACK_DETECTED;

	//Referpg44 of WM8731 datasheet
	if(codec_config_reg(CODEC_DACPD_IDX, CODEC_DACPD_OFFST, CODEC_DACPD_MSK, 0x1))	return	I2C_NACK_DETECTED;

	return I2C_OK;

}

I2C_RES codec_pwr_off_n_on(CODEC_PWR_ON_OFF val){	//0->Power up, 1->Power Down
	return codec_config_reg(CODEC_PWROFF_IDX, CODEC_PWROFF_OFFST, CODEC_PWROFF_MSK, val);
}

I2C_RES codec_linein_pwr_dwn_n_up(CODEC_PWR_ON_OFF val){	//0->Power up, 1->Power Down
	return codec_config_reg(CODEC_LINEINPD_IDX, CODEC_LINEINPD_OFFST, CODEC_LINEINPD_MSK, val);
}

I2C_RES codec_lineout_pwr_dwn_n_up(CODEC_PWR_ON_OFF val){
	return codec_config_reg(CODEC_OUTPD_IDX, CODEC_OUTPD_OFFST, CODEC_OUTPD_MSK, val);
}

I2C_RES codec_adc_hpf_enable(CODEC_PWR_ON_OFF val){
	return codec_config_reg(CODEC_ADC_HPD_IDX, CODEC_ADC_HPD_OFFST, CODEC_ADC_HPD_MSK, val);
}

I2C_RES codec_adc_pwr_dwn_n_up(CODEC_PWR_ON_OFF val){
	return codec_config_reg(CODEC_ADCPD_IDX, CODEC_ADCPD_OFFST, CODEC_ADCPD_MSK, val);
}

I2C_RES codec_sr_update(SR_SEL val){
	return codec_config_reg(CODEC_SR_IDX, CODEC_SR_OFFST, CODEC_SR_MSK, val);
}

I2C_RES codec_iwl_update(CODEC_IWL val){
	return codec_config_reg(CODEC_IWL_IDX, CODEC_IWL_OFFST, CODEC_IWL_MSK, val);
}

void codec_dump_regs(){
	alt_u8 i;

	alt_printf("CODEC Regs - \r\n");

	for(i=0; i<NO_OF_CODEC_REGS; i++){
		switch(i) {
			case CODEC_LEFT_LINE_IN_REG_IDX: {
				alt_printf("[0x%x] LEFT_LINE_IN REG - 0x%x\r\n",i,codec_shadow_reg[i]);
				alt_printf("\tLRIN BOTH : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_LRIN_BOTH_IDX,CODEC_LRIN_BOTH_OFFST,CODEC_LRIN_BOTH_MSK));
				alt_printf("\tLIN MUTE  : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_LIN_MUTE_IDX,CODEC_LIN_MUTE_OFFST,CODEC_LIN_MUTE_MSK));
				alt_printf("\tLIN VOL   : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_LINVOL_IDX,CODEC_LINVOL_OFFST,CODEC_LINVOL_MSK));
				continue;
			}

			case CODEC_RIGHT_LINE_IN_REG_IDX: {
				alt_printf("[0x%x] RIGHT_LINE_IN REG - 0x%x\r\n",i,codec_shadow_reg[i]);
				alt_printf("\tRLIN BOTH : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_RLIN_BOTH_IDX,CODEC_RLIN_BOTH_OFFST,CODEC_RLIN_BOTH_MSK));
				alt_printf("\tRIN MUTE  : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_RIN_MUTE_IDX,CODEC_RIN_MUTE_OFFST,CODEC_RIN_MUTE_MSK));
				alt_printf("\tRIN VOL   : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_RINVOL_IDX,CODEC_RINVOL_OFFST,CODEC_RINVOL_MSK));
				continue;
			}

			case CODEC_LEFT_HP_OUT_REG_IDX: {
				alt_printf("[0x%x] LEFT_HP_OUT REG - 0x%x\r\n",i,codec_shadow_reg[i]);
				alt_printf("\tLRHP BOTH : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_LRHP_BOTH_IDX,CODEC_LRHP_BOTH_OFFST,CODEC_LRHP_BOTH_MSK));
				alt_printf("\tLZCEN     : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_LZCEN_IDX,CODEC_LZCEN_OFFST,CODEC_LZCEN_MSK));
				alt_printf("\tLHPVOL    : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_LHPVOL_IDX,CODEC_LHPVOL_OFFST,CODEC_LHPVOL_MSK));
				continue;
			}

			case CODEC_RIGHT_HP_OUT_REG_IDX: {
				alt_printf("[0x%x] RIGHT_HP_OUT REG - 0x%x\r\n",i,codec_shadow_reg[i]);
				alt_printf("\tRLHP BOTH : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_RLHP_BOTH_IDX,CODEC_RLHP_BOTH_OFFST,CODEC_RLHP_BOTH_MSK));
				alt_printf("\tRZCEN     : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_RZCEN_IDX,CODEC_RZCEN_OFFST,CODEC_RZCEN_MSK));
				alt_printf("\tRHPVOL    : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_RHPVOL_IDX,CODEC_RHPVOL_OFFST,CODEC_RHPVOL_MSK));
				continue;
			}

			case CODEC_ANALOG_AUD_PATH_REG_IDX: {
				alt_printf("[0x%x] ANALOG_AUDIO_PATH REG - 0x%x\r\n",i,codec_shadow_reg[i]);
				alt_printf("\tSIDE ATT  : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_SIDE_ATT_IDX,CODEC_SIDE_ATT_OFFST,CODEC_SIDE_ATT_MSK));
				alt_printf("\tSIDE TONE : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_SIDE_TONE_IDX,CODEC_SIDE_TONE_OFFST,CODEC_SIDE_TONE_MSK));
				alt_printf("\tDAC SEL   : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_DAC_SEL_IDX,CODEC_DAC_SEL_OFFST,CODEC_DAC_SEL_MSK));
				alt_printf("\tBYPASS    : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_BYPASS_IDX,CODEC_BYPASS_OFFST,CODEC_BYPASS_MSK));
				alt_printf("\tINSEL     : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_INSEL_IDX,CODEC_INSEL_OFFST,CODEC_INSEL_MSK));
				alt_printf("\tMUTE MIC  : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_MUTE_MIC_IDX,CODEC_MUTE_MIC_OFFST,CODEC_MUTE_MIC_MSK));
				alt_printf("\tMUTE BOOST: 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_MIC_BOOST_IDX,CODEC_MIC_BOOST_OFFST,CODEC_MIC_BOOST_MSK));
				continue;
			}

			case CODEC_DIGITAL_AUD_PATH_REG_IDX: {
				alt_printf("[0x%x] DIGITAL_AUDIO_PATH REG - 0x%x\r\n",i,codec_shadow_reg[i]);
				alt_printf("\tHPOR      : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_HPOR_IDX,CODEC_HPOR_OFFST,CODEC_HPOR_MSK));
				alt_printf("\tDAC MUTE  : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_DAC_MU_IDX,CODEC_DAC_MU_OFFST,CODEC_DAC_MU_MSK));
				alt_printf("\tDE-EMPH   : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_DEEMPH_IDX,CODEC_DEEMPH_OFFST,CODEC_DEEMPH_MSK));
				alt_printf("\tADC HPD   : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_ADC_HPD_IDX,CODEC_ADC_HPD_OFFST,CODEC_ADC_HPD_MSK));
				continue;
			}

			case CODEC_POWER_DOWN_REG_IDX: {
				alt_printf("[0x%x] POWER_DOWN REG - 0x%x\r\n",i,codec_shadow_reg[i]);
				alt_printf("\tPWR OFF   : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_PWROFF_IDX,CODEC_PWROFF_OFFST,CODEC_PWROFF_MSK));
				alt_printf("\tCLK OUTPD : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_CLKOUTPD_IDX,CODEC_CLKOUTPD_OFFST,CODEC_CLKOUTPD_MSK));
				alt_printf("\tOSCPD     : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_OSCPD_IDX,CODEC_OSCPD_OFFST,CODEC_OSCPD_MSK));
				alt_printf("\tOUTPD     : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_OUTPD_IDX,CODEC_OUTPD_OFFST,CODEC_OUTPD_MSK));
				alt_printf("\tDACPD     : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_DACPD_IDX,CODEC_DACPD_OFFST,CODEC_DACPD_MSK));
				alt_printf("\tADCPD     : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_ADCPD_IDX,CODEC_ADCPD_OFFST,CODEC_ADCPD_MSK));
				alt_printf("\tMICPD     : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_MICPD_IDX,CODEC_MICPD_OFFST,CODEC_MICPD_MSK));
				alt_printf("\tLINEINPD  : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_LINEINPD_IDX,CODEC_LINEINPD_OFFST,CODEC_LINEINPD_MSK));
				continue;
			}

			case CODEC_DIGITAL_AUD_IF_FMT_REG_IDX: {
				alt_printf("[0x%x] DIGITAL_AUD_INTF_FMT REG - 0x%x\r\n",i,codec_shadow_reg[i]);
				alt_printf("\tBCLK INV  : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_BCLK_INV_IDX,CODEC_BCLK_INV_OFFST,CODEC_BCLK_INV_MSK));
				alt_printf("\tMS        : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_MS_IDX,CODEC_MS_OFFST,CODEC_MS_MSK));
				alt_printf("\tLRSWAP    : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_LRSWAP_IDX,CODEC_LRSWAP_OFFST,CODEC_LRSWAP_MSK));
				alt_printf("\tLRP       : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_LRP_IDX,CODEC_LRP_OFFST,CODEC_LRP_MSK));
				alt_printf("\tIWL       : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_IWL_IDX,CODEC_IWL_OFFST,CODEC_IWL_MSK));
				alt_printf("\tFORMAT    : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_FORMAT_IDX,CODEC_FORMAT_OFFST,CODEC_FORMAT_MSK));
				continue;
			}

			case CODEC_SAMPLING_CTRL_REG_IDX: {
				alt_printf("[0x%x] SAMPLING_CNTRL REG - 0x%x\r\n",i,codec_shadow_reg[i]);
				alt_printf("\tCLKO DIV2 : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_CLKO_DIV2_IDX,CODEC_CLKO_DIV2_OFFST,CODEC_CLKO_DIV2_MSK));
				alt_printf("\tCLKI DIV2 : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_CLKI_DIV2_IDX,CODEC_CLKI_DIV2_OFFST,CODEC_CLKI_DIV2_MSK));
				alt_printf("\tSR        : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_SR_IDX,CODEC_SR_OFFST,CODEC_SR_MSK));
				alt_printf("\tBOSR      : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_BOSR_IDX,CODEC_BOSR_OFFST,CODEC_BOSR_MSK));
				alt_printf("\tUSB/NORM  : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_USB_NORM_IDX,CODEC_USB_NORM_OFFST,CODEC_USB_NORM_MSK));
				continue;
			}

			case CODEC_ACTIVE_CTRL_REG_IDX: {
				alt_printf("[0x%x] SAMPLING_CNTRL REG - 0x%x\r\n",i,codec_shadow_reg[i]);
				alt_printf("\tACTIVE    : 0x%x\r\n",CODEC_EXTRACT_FIELD(CODEC_ACTIVE_IDX,CODEC_ACTIVE_OFFST,CODEC_ACTIVE_MSK));
				continue;
			}

			default: {
				continue;
			}
		}
	}

	return;
}

I2C_RES codec_bypass_enable(){
	return codec_config_reg(CODEC_BYPASS_IDX, CODEC_BYPASS_OFFST, CODEC_BYPASS_MSK, 1);
}

I2C_RES codec_bypass_disable(){
	return codec_config_reg(CODEC_BYPASS_IDX, CODEC_BYPASS_OFFST, CODEC_BYPASS_MSK, 0);
}

I2C_RES codec_play() {
	reset_acache();

	if(codec_dsp_if_activate())	return	I2C_NACK_DETECTED;

	enable_adc_drvr();

	if(codec_dac_activate())	return	I2C_NACK_DETECTED;

	enable_dac_drvr();

	chThdSleepMilliseconds(1);

	if(codec_bypass_disable())	return	I2C_NACK_DETECTED;

	return I2C_OK;
}

I2C_RES codec_stop(){
	if(codec_bypass_enable())	return	I2C_NACK_DETECTED;

	if(codec_dac_inactivate())	return	I2C_NACK_DETECTED;

	disable_dac_drvr();
	disable_adc_drvr();

	if(codec_dsp_if_inactivate())	return	I2C_NACK_DETECTED;

	return I2C_OK;
}
