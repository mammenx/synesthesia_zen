//Block Code
parameter ACORTEX_I2CM_CODE      =    4'd0;
parameter ACORTEX_CMUX_CODE      =    4'd1;
parameter ACORTEX_WMDRVR_CODE    =    4'd2;
parameter ACORTEX_ACACHE_CODE    =    4'd3;

//I2C Master register addresses
parameter ACORTEX_I2CM_STATUS_REG_ADDR  = 8'd0;
parameter ACORTEX_I2CM_ADDR_REG_ADDR    = 8'd1;
parameter ACORTEX_I2CM_DATA_REG_ADDR    = 8'd2;
parameter ACORTEX_I2CM_CLK_DIV_REG_ADDR = 8'd3;

//Clock Mux register addresses
parameter ACORTEX_CMUX_CLK_SEL_REG_ADDR = 8'd0;

//WM8731 Driver register addresses
parameter ACORTEX_WMDRVR_CTRL_REG_ADDR  = 8'd0;
parameter ACORTEX_WMDRVR_STATUS_REG_ADDR= 8'd1;
parameter ACORTEX_WMDRVR_FS_DIV_REG_ADDR= 8'd2;

//Audio Cache register addresses
parameter ACORTEX_ACACHE_CTRL_REG_ADDR  = 8'd0;
parameter ACORTEX_ACACHE_DATA_BASE_ADDR = 8'h80;
