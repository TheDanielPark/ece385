module regbit12 (input logic Clk, Reset, Load,
						input logic[11:0] Din,
						output logic[11:0] Dout

);

always_ff @ (posedge Clk)
	begin
		if (Load)
			Dout <= Din;
		else if (Reset)
			Dout <= 12'b0;
			
	end

endmodule
