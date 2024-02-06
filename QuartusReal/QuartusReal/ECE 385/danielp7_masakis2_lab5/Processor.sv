
module Processor (input logic   Clk,     // Internal
                                Reset,   // Push button 0
                                ClearA_LoadB,   // Push button 2
                                Run, // Push button 3
                  input  logic [7:0]  Din,     // i
 //                 output logic [3:0]  LED,     // DEBUG
                  output logic [7:0]  Aval,    // D
                                Bval,    // DEBUG 
                  output logic [6:0]  AhexL,
                                AhexU,
                                BhexL,
                                BhexU,
						output logic X
										  );

	 //local logic variables go here
	 logic Clr_Ld, Shift, Add, Sub, MShift, AShift_Out;
	 logic [7:0] Switches, Aout, Ain, A, B;
 	 logic Reset_SH, ClearA_LoadB_SH, Run_SH, clearA;

	 //We can use the "assign" statement to do simple combinational logic

	 assign Switches = Din;
 	 //assign LED = {Run_SH,ClearA_LoadB_SH,Reset_SH}; //Concatenate is a common operation in HDL
	 assign MShift = B[0];
	 assign Aval = A;
	 assign Bval = B;
	 //Instantiation of modules here
	 logic x_fin;
	 always_ff @(posedge Clk)
	 begin
		if (Clr_Ld | Reset_SH | clearA)
			x_fin <= 1'b0;
		else if (Add)
			x_fin<= X;
	end	
	 
	 //Command to call control unit and set variables
	 control_unit control (
			.Clk (Clk), .Reset (Reset_SH), .Run (Run_SH), .ClearA_LoadB (ClearA_LoadB_SH), .MShift (MShift),
		   .Clr_Ld (Clr_Ld), .Shift (Shift), .Add (Add), .Sub (Sub), .clearA (clearA)
	 );
	 
	 //Command to call shift register A and set values
	 shift_register regA (
			.Clk (Clk), .Reset (Clr_Ld | Reset_SH | clearA), .Shift_In (x_fin), .Load (Add), .Shift_En (Shift),
              .D (Ain),// 8 bit input
              .Shift_Out (AShift_Out),
              .Data_Out (A)
	 );
	 
	 //Command to call shift register B and set values
	 shift_register regB (
			.Clk (Clk), .Reset (Reset_SH), .Shift_In (AShift_Out), .Load (Clr_Ld), .Shift_En (Shift),
              .D (Switches),// 8 bit input
              .Shift_Out (),
              .Data_Out (B)	
	 );
	 
	 //Command to use the ripple adder and get values
	 ripple_adder adder (
			.A (A),
			.B (Switches),
			.sub (Sub),
			.Sum (Ain),
			.X (X)
	 );
	 
	 //Commands to display hex
	 HexDriver        HexAL (
                        .In0(A[3:0]),
                        .Out0(AhexL) );
	 HexDriver        HexBL (
                        .In0(B[3:0]),
                        .Out0(BhexL) );
								
	 //When you extend to 8-bits, you will need more HEX drivers to view upper nibble of registers, for now set to 0
	 HexDriver        HexAU (
                        .In0(A[7:4]), //Changed to the upper 4 bits of the 8 bit input
                        .Out0(AhexU) );	
	 HexDriver        HexBU (
                       .In0(B[7:4]),//Changed to the upper 4 bits of the 8 bit input
                        .Out0(BhexU) );
								
	  //Input synchronizers required for asynchronous inputs (in this case, from the switches)
	  //These are array module instantiations
	  //Note: S stands for SYNCHRONIZED, H stands for active HIGH
	  //Note: We can invert the levels inside the port assignments
	  synchronizer button_sync[2:0] (Clk, {~Reset, ~ClearA_LoadB, ~Run}, {Reset_SH, ClearA_LoadB_SH, Run_SH});
	//  synchronizer Din_sync[7:0] (Clk, Din, Din_S);//CHanged to 8 bits because 8 bit processor

	  
endmodule