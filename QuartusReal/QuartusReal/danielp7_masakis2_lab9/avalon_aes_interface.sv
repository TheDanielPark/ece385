/************************************************************************
Avalon-MM Interface for AES Decryption IP Core

Dong Kai Wang, Fall 2017

For use with ECE 385 Experiment 9
University of Illinois ECE Department

Register Map:

 0-3 : 4x 32bit AES Key
 4-7 : 4x 32bit AES Encrypted Message
 8-11: 4x 32bit AES Decrypted Message
   12: Not Used
	13: Not Used
   14: 32bit Start Register
   15: 32bit Done Register

************************************************************************/

module avalon_aes_interface (
	// Avalon Clock Input
	input logic CLK,
	
	// Avalon Reset Input
	input logic RESET,
	
	// Avalon-MM Slave Signals
	input  logic AVL_READ,					// Avalon-MM Read
	input  logic AVL_WRITE,					// Avalon-MM Write
	input  logic AVL_CS,						// Avalon-MM Chip Select
	input  logic [3:0] AVL_BYTE_EN,		// Avalon-MM Byte Enable
	input  logic [3:0] AVL_ADDR,			// Avalon-MM Address
	input  logic [31:0] AVL_WRITEDATA,	// Avalon-MM Write Data
	output logic [31:0] AVL_READDATA,	// Avalon-MM Read Data
	
	// Exported Conduit
	output logic [31:0] EXPORT_DATA		// Exported Conduit Signal to LEDs
);

	logic AES_END, AES_BEGIN;
	logic [31:0] registers [15:0];
	logic [127:0] decode;

	always_ff @ (posedge CLK)
	begin
	
		if(RESET) 
			begin
				registers[0] <= 32'd0;
				registers[1] <= 32'd0;
				registers[2] <= 32'd0;
				registers[3] <= 32'd0;
				registers[4] <= 32'd0;
				registers[5] <= 32'd0;
				registers[6] <= 32'd0;
				registers[7] <= 32'd0;
				registers[8] <= 32'd0;
				registers[9] <= 32'd0;
				registers[10] <= 32'd0;
				registers[11] <= 32'd0;
				registers[12] <= 32'd0;
				registers[13] <= 32'd0;
				registers[14] <= 32'd0;
				registers[15] <= 32'd0;
			end
			
		else if(AVL_WRITE && AVL_CS) 
			begin
				if(AVL_BYTE_EN[0] == 1'b1)
					registers[AVL_ADDR][7:0] <= AVL_WRITEDATA[7:0];
				if(AVL_BYTE_EN[1] == 1'b1)
					registers[AVL_ADDR][15:8] <= AVL_WRITEDATA[15:8];
				if(AVL_BYTE_EN[2] == 1'b1)
					registers[AVL_ADDR][23:16] <= AVL_WRITEDATA[23:16];
				if(AVL_BYTE_EN[3] == 1'b1)
					registers[AVL_ADDR][31:24] <= AVL_WRITEDATA[31:24];
			end
			
		else
			begin
				AES_BEGIN <= registers[14][0];
				registers[8] <= decode[127:96]; 
				registers[9] <= decode[95:64];
				registers[10] <= decode[63:32];
				registers[11] <= decode[31:0];
				registers[15][0] <= AES_END;
			end
	end

	always_comb 
	begin
		AVL_READDATA = (AVL_READ && AVL_CS) ? registers[AVL_ADDR] : 32'd0;
		EXPORT_DATA = {registers[8][31:16], registers[15][15:0]}; // change register 0-3
	end 

	/*AES AES (
			.CLK(CLK),
			.RESET(RESET),
			.AES_START(AES_BEGIN),
			.AES_DONE(AES_END),
			.AES_KEY({registers[0], registers[1], registers[2], registers[3]}),
			.AES_MSG_ENC({registers[4], registers[5], registers[6], registers[7]}),
			.AES_MSG_DEC(decode)
	);
*/
endmodule
