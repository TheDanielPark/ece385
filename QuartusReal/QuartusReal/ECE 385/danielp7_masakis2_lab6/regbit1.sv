module regbit1 (input logic Clk, Reset, Load,
						input logic Din,
						output logic Dout
);

always_ff @ (posedge Clk)
	begin
		if (Load)
			Dout <= Din;
		else if (Reset)
			Dout <= 1'b0;
			
	end


	
endmodule