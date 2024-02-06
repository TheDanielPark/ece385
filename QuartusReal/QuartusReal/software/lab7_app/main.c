// Main.c - makes LEDG0 on DE2-115 board blink if NIOS II is set up correctly
// for ECE 385 - University of Illinois - Electrical and Computer Engineering
// Author: Zuofu Cheng

int main()
{
	int i = 0;
	volatile unsigned int *LED_PIO = (unsigned int*)0x80; //make a pointer to access the PIO block
	volatile unsigned int *SW_PIO = (unsigned int*)0x60;
	volatile unsigned int *KEY_PIO = (unsigned int*)0x50;

	*LED_PIO = 0; //clear all LEDs
	while ( (1+1) != 3) //infinite loop
	{
		if (*KEY_PIO==0b0111){
			*LED_PIO += *SW_PIO;
			*LED_PIO = *LED_PIO % 256;
			while(*KEY_PIO!=0b1111);
		}
		else if (*KEY_PIO==0b1011){
			*LED_PIO = 0;
			while(*KEY_PIO!=0b1111);
		}


	/*	for (i = 0; i < 100000; i++); //software delay
		*LED_PIO |= 0x1; //set LSB
		for (i = 0; i < 100000; i++); //software delay
		*LED_PIO &= ~0x1; //clear LSB*/
	}
	return 1; //never gets here
}