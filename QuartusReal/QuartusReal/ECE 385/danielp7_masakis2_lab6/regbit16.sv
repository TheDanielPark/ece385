module regbit16 (input logic Clk, Reset, Load,
						input logic[15:0] Din,
						output logic[15:0] Dout

);

always_ff @ (posedge Clk)
	begin
		if (Load)
			Dout <= Din;
		else if (Reset)
			Dout <= 16'b0;
			
	end


endmodule
