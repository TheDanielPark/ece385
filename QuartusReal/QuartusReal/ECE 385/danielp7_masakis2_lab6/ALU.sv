module ALU (input logic [15:0] R1, R2, input logic[1:0] ALUK,
					output logic[15:0] out
);
	always_comb
		begin
			case (ALUK)
			
				2'b00: //ADD
					out = R1 + R2;
				2'b01: //AND
					out = R1 & R2;
				2'b10: //NOT
					out = ~R1;
				2'b11: //PASSA
					out = R1;
						
			endcase
		end
endmodule