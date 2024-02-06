module regfile (input logic [15:0] BUS, input logic [2:0] DRMUXOUT,
					 input logic [2:0] SR1MUXOUT, SR2, input logic LD_REG, Clk, Reset, 
					 output logic [15:0] SR2OUT, SR1OUT
);

logic LDR0, LDR1, LDR2, LDR3, LDR4, LDR5, LDR6, LDR7;
logic[15:0] OUTR0, OUTR1, OUTR2, OUTR3, OUTR4, OUTR5, OUTR6, OUTR7;
always_comb //LDMUX
   begin
		LDR0 = 1'b0;
		LDR1 = 1'b0;
		LDR2 = 1'b0;
		LDR3 = 1'b0;
		LDR4 = 1'b0;
		LDR5 = 1'b0;
		LDR6 = 1'b0;
		LDR7 = 1'b0;

        case (DRMUXOUT)
				3'b000: LDR0 = 1'b1;
				3'b001: LDR1 = 1'b1;
				3'b010: LDR2 = 1'b1;
				3'b011: LDR3 = 1'b1;
				3'b100: LDR4 = 1'b1;
				3'b101: LDR5 = 1'b1;
				3'b110: LDR6 = 1'b1;
				3'b111: LDR7 = 1'b1;
				default :
				begin
				end
		  endcase
	end	
	
regbit16 R0 (.Clk, .Reset, .Load (LDR0 & LD_REG), .Din (BUS), .Dout (OUTR0));
regbit16 R1 (.Clk, .Reset, .Load (LDR1 & LD_REG), .Din (BUS), .Dout (OUTR1));
regbit16 R2 (.Clk, .Reset, .Load (LDR2 & LD_REG), .Din (BUS), .Dout (OUTR2));
regbit16 R3 (.Clk, .Reset, .Load (LDR3 & LD_REG), .Din (BUS), .Dout (OUTR3));
regbit16 R4 (.Clk, .Reset, .Load (LDR4 & LD_REG), .Din (BUS), .Dout (OUTR4));
regbit16 R5 (.Clk, .Reset, .Load (LDR5 & LD_REG), .Din (BUS), .Dout (OUTR5));
regbit16 R6 (.Clk, .Reset, .Load (LDR6 & LD_REG), .Din (BUS), .Dout (OUTR6));
regbit16 R7 (.Clk, .Reset, .Load (LDR7 & LD_REG), .Din (BUS), .Dout (OUTR7));

always_comb //SR1MUXOUT
   begin
        case (SR1MUXOUT)
				3'b000: SR1OUT = OUTR0;
				3'b001: SR1OUT = OUTR1;
				3'b010: SR1OUT = OUTR2;
				3'b011: SR1OUT = OUTR3;
				3'b100: SR1OUT = OUTR4;
				3'b101: SR1OUT = OUTR5;
				3'b110: SR1OUT = OUTR6;
				3'b111: SR1OUT = OUTR7;
				default :
				begin
				end
		  endcase
	end	
	
always_comb //SR2
   begin
        case (SR2)
				3'b000: SR2OUT = OUTR0;
				3'b001: SR2OUT = OUTR1;
				3'b010: SR2OUT = OUTR2;
				3'b011: SR2OUT = OUTR3;
				3'b100: SR2OUT = OUTR4;
				3'b101: SR2OUT = OUTR5;
				3'b110: SR2OUT = OUTR6;
				3'b111: SR2OUT = OUTR7;
				default :
				begin
				end
		  endcase
	end	
endmodule
