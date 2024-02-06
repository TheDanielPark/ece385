module reg_4 (input  logic Clk, Reset, Shift_In, Load, Shift_En,
              input  logic [7:0]  D,//Changed to 8 bits because it is 8 bit processor
              output logic Shift_Out,
              output logic [7:0]  Data_Out);//Changed to 8 bits because it is 8 bit processor

    always_ff @ (posedge Clk)
    begin
	 	 if (Reset) //notice, this is a sycnrhonous reset, which is recommended on the FPGA
			  Data_Out <= 8'h0;
		 else if (Load)
			  Data_Out <= D;
		 else if (Shift_En)
		 begin
			  //concatenate shifted in data to the previous left-most 3 bits
			  //note this works because we are in always_ff procedure block
			  Data_Out <= { Shift_In, Data_Out[7:1] }; //Changed to 7 bits but kept the last bit out because it shifts out
	    end
    end
	
    assign Shift_Out = Data_Out[0];

endmodule
