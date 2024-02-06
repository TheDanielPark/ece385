//------------------------------------------------------------------------------
// Company:        UIUC ECE Dept.
// Engineer:       Stephen Kempf
//
// Create Date:    
// Design Name:    ECE 385 Lab 6 Given Code - SLC-3 
// Module Name:    SLC3
//
// Comments:
//    Revised 03-22-2007
//    Spring 2007 Distribution
//    Revised 07-26-2013
//    Spring 2015 Distribution
//    Revised 09-22-2015 
//    Revised 10-19-2017 
//    spring 2018 Distribution
//
//------------------------------------------------------------------------------
module slc3(
    input logic [15:0] S,
    input logic Clk, Reset, Run, Continue,
    output logic [11:0] LED,
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
    output logic CE, UB, LB, OE, WE,
    output logic [19:0] ADDR,
    inout wire [15:0] Data //tristate buffers need to be of type wire
	 
	 //output logic [15:0] MARout, MDRout, IRout, PCout
);

// Declaration of push button active high signals
logic Reset_ah, Continue_ah, Run_ah;

synchronizer sync1 (.Clk, .d(~Reset), .q(Reset_ah));
synchronizer sync2 (.Clk, .d(~Continue), .q(Continue_ah));
synchronizer sync3 (.Clk, .d(~Run), .q(Run_ah));

//assign MARout = MAR;
//assign MDRout = MDR;
//assign IRout = IR;
//assign PCout = PC;

/* assign Reset_ah = ~Reset;
assign Continue_ah = ~Continue;
assign Run_ah = ~Run;
*/
// Internal connections
logic BEN;
logic LD_MAR, LD_MDR, LD_IR, LD_BEN, LD_CC, LD_REG, LD_PC, LD_LED;
logic GatePC, GateMDR, GateALU, GateMARMUX;
logic [1:0] PCMUX, ADDR2MUX, ALUK;
logic DRMUX, SR1MUX, SR2MUX, ADDR1MUX;
logic MIO_EN;

logic [15:0] MDR_In;
logic [15:0] MAR, MDR, IR, PC;
logic [15:0] Data_from_SRAM, Data_to_SRAM;
logic [15:0] BUS, PC_In;
logic [2:0] DRMUXOUT, SR1MUXOUT;
logic [15:0] SR1OUT, SR2OUT, ALUOUT, ADDR1MUXOUT, ADDR2MUXOUT, ADDEROUT, MDR_In2, SR2MUXOUT;
logic N_In, P_In, Z_In, N_Out, P_Out, Z_Out;

// Signals being displayed on hex display
logic [3:0][3:0] hex_4;

//Our code
regbit12 LED1 (.Clk, .Reset (Reset_ah), .Load(LD_LED),
						.Din (IR[11:0]),
						.Dout(LED)

);

regbit16 REG_PC (.Clk, .Reset(Reset_ah), .Load (LD_PC),
						.Din (PC_In),
						.Dout (PC));

regbit16 REG_MDR (.Clk, .Reset (Reset_ah), .Load (LD_MDR),
						.Din (MDR_In2),
						.Dout (MDR));

regbit16 REG_IR (.Clk, .Reset (Reset_ah), .Load (LD_IR),
						.Din (BUS),
						.Dout (IR));

regbit16 REG_MAR (.Clk, .Reset(Reset_ah), .Load (LD_MAR),
						.Din (BUS),
						.Dout (MAR));

regfile regfile1 (.BUS, .DRMUXOUT,
					 .SR1MUXOUT, .SR2(IR[2:0]), .LD_REG, .Clk, .Reset(Reset_ah), 
					 .SR2OUT, .SR1OUT );

ALU ALU1 (.R1(SR1OUT), .R2(SR2MUXOUT), .ALUK,
					.out(ALUOUT) );

ALU ADDER (.R1(ADDR1MUXOUT), .R2(ADDR2MUXOUT), .ALUK(2'b00),
					.out(ADDEROUT) );
regbit1 regN(.Clk, .Reset(Reset_ah), .Load (LD_CC),
						.Din (N_In),
						.Dout (N_Out)
);
regbit1 regZ(.Clk, .Reset(Reset_ah), .Load (LD_CC),
						.Din (Z_In),
						.Dout (Z_Out)
);
regbit1 regP(.Clk, .Reset(Reset_ah), .Load (LD_CC),
						.Din (P_In),
						.Dout (P_Out)
);
regbit1 regBEN(.Clk, .Reset(Reset_ah), .Load (LD_BEN),
						.Din ( (IR[11]&N_Out)|(IR[10]&Z_Out)|(IR[9]&P_Out) ),
						.Dout (BEN)
);

always_comb // NZP Logic
	begin
		N_In = 1'b0;
		Z_In = 1'b0;
		P_In = 1'b0;

		case (BUS)
			16'b0 : 	Z_In = 1'b1;
			default :
			begin
				if(BUS[15])
					N_In = 1'b1;
				else
					P_In = 1'b1;
			end

		endcase
	end

always_comb //ADDR2MUX
   begin
       unique case (ADDR2MUX)
				2'b00: ADDR2MUXOUT = 16'b0;
				2'b01: ADDR2MUXOUT = {{10{IR[5]}}, IR[5:0]};
				2'b10: ADDR2MUXOUT = {{7{IR[8]}}, IR[8:0]};
				2'b11: ADDR2MUXOUT = {{5{IR[10]}}, IR[10:0]};

		  endcase
	end		
					
always_comb //ADDR1MUX
   begin
       unique case (ADDR1MUX)
				1'b0: ADDR1MUXOUT = PC;
				1'b1: ADDR1MUXOUT = SR1OUT;
				
		  endcase
	end		
					
always_comb //PCMUX
   begin
        case (PCMUX)
				2'b00: PC_In = PC + 1'b1;
				2'b01: PC_In = BUS;
				2'b10: PC_In = ADDEROUT;
				2'b11: PC_In = 16'b0;
				default :
				begin
				end
		  endcase
	end							
						
always_comb //MDRMUX
   begin
        case (MIO_EN)
				1'b0: MDR_In2 = BUS;
				1'b1: MDR_In2 = MDR_In;
				default :
				begin
				end
		  endcase
	end						
						
always_comb //GATEMUX
   begin
        case ({GatePC, GateMDR, GateALU, GateMARMUX})
				4'b1000: BUS = PC;
				4'b0100: BUS = MDR;
				4'b0010: BUS = ALUOUT;
				4'b0001: BUS = ADDEROUT;
				
			default : 
				begin
					 BUS = 16'bZZZZZZZZZZZZZZZZ;
				end
		  endcase
	end

always_comb //DRMUX
   begin
        case (DRMUX)
		  
				1'b0: DRMUXOUT = IR[11:9];
				1'b1: DRMUXOUT = 3'b111;
			
				default :
				begin
				end
		  endcase
	end						
		
always_comb //SR1MUX
   begin
        case (SR1MUX)
				1'b0: SR1MUXOUT = IR[11:9];		
				1'b1: SR1MUXOUT = IR[8:6];
				default :
				begin
				end
		  endcase
	end						

always_comb //SR2MUX
   begin
        case (SR2MUX)
				1'b0: SR2MUXOUT = SR2OUT;		
				1'b1: SR2MUXOUT = {{11{IR[4]}}, IR[4:0]};
				default :
				begin
				end
		  endcase
	end			

// For week 1, hexdrivers will display IR. Comment out these in week 2.
/*
HexDriver hex_driver3 (SR1OUT[15:12], HEX3);
HexDriver hex_driver2 (SR1OUT[11:8], HEX2);
HexDriver hex_driver1 (SR1OUT[7:4], HEX1);
HexDriver hex_driver0 (SR1OUT[3:0], HEX0);
*/
// For week 2, hexdrivers will be mounted to Mem2IO

HexDriver hex_driver3 (hex_4[3][3:0], HEX3);
HexDriver hex_driver2 (hex_4[2][3:0], HEX2);
HexDriver hex_driver1 (hex_4[1][3:0], HEX1);
HexDriver hex_driver0 (hex_4[0][3:0], HEX0);


// The other hex display will show PC for both weeks.
HexDriver hex_driver7 (PC[15:12], HEX7);
HexDriver hex_driver6 (PC[11:8], HEX6);
HexDriver hex_driver5 (PC[7:4], HEX5);
HexDriver hex_driver4 (PC[3:0], HEX4);

// Connect MAR to ADDR, which is also connected as an input into MEM2IO.
// MEM2IO will determine what gets put onto Data_CPU (which serves as a potential
// input into MDR)
assign ADDR = { 4'b00, MAR }; //Note, our external SRAM chip is 1Mx16, but address space is only 64Kx16
assign MIO_EN = ~OE;

// You need to make your own datapath module and connect everything to the datapath
// Be careful about whether Reset is active high or low
datapath d0 (/* Please fill in the signals.... */);

// Our SRAM and I/O controller
Mem2IO memory_subsystem(
    .*, .Reset(Reset_ah), .ADDR(ADDR), .Switches(S),
    .HEX0(hex_4[0][3:0]), .HEX1(hex_4[1][3:0]), .HEX2(hex_4[2][3:0]), .HEX3(hex_4[3][3:0]),
    .Data_from_CPU(MDR), .Data_to_CPU(MDR_In),
    .Data_from_SRAM(Data_from_SRAM), .Data_to_SRAM(Data_to_SRAM)
);

// The tri-state buffer serves as the interface between Mem2IO and SRAM
tristate #(.N(16)) tr0(
    .Clk(Clk), .tristate_output_enable(~WE), .Data_write(Data_to_SRAM), .Data_read(Data_from_SRAM), .Data(Data)
);

// State machine and control signals
ISDU state_controller(
    .*, .Reset(Reset_ah), .Run(Run_ah), .Continue(Continue_ah),
    .Opcode(IR[15:12]), .IR_5(IR[5]), .IR_11(IR[11]),
    .Mem_CE(CE), .Mem_UB(UB), .Mem_LB(LB), .Mem_OE(OE), .Mem_WE(WE)
);

endmodule
