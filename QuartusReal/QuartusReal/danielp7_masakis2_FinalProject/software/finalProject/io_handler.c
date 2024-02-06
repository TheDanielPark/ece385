//io_handler.c
#include "io_handler.h"
#include <stdio.h>

void IO_init(void)
{
	*otg_hpi_reset = 1;
	*otg_hpi_cs = 1;
	*otg_hpi_r = 1;
	*otg_hpi_w = 1;
	*otg_hpi_address = 0;
	*otg_hpi_data = 0;
	// Reset OTG chip
	*otg_hpi_cs = 0;
	*otg_hpi_reset = 0;
	*otg_hpi_reset = 1;
	*otg_hpi_cs = 1;
}

void IO_write(alt_u8 Address, alt_u16 Data)
{
//*************************************************************************//
//									TASK								   //
//*************************************************************************//
//							Write this function							   //
//*************************************************************************//
	*otg_hpi_address =  Address; //set the address to address
	*otg_hpi_cs =  0; // make cs and write low to make it write
	*otg_hpi_w =  0;
	*otg_hpi_data =  Data; //set the data
	*otg_hpi_w =  1;
	*otg_hpi_cs =  1;    //reset the write and cs signals back to high
}

alt_u16 IO_read(alt_u8 Address)
{
	alt_u16 temp;
//*************************************************************************//
//									TASK								   //
//*************************************************************************//
//							Write this function							   //
//*************************************************************************//
	//printf("%x\n",temp);
	*otg_hpi_address =  Address; //set the address
	*otg_hpi_r =  0;
	*otg_hpi_cs =  0; //set cs and read to low in order to make it active
	temp =  *otg_hpi_data; //set temp to the data stored
	*otg_hpi_r =  1;
	*otg_hpi_cs =  1; //set the read and cs values back to high
	return temp; //return the data stored
}
