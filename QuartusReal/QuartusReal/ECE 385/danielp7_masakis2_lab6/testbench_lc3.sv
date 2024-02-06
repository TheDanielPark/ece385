module testbench_lc3 ();


timeunit 10ns;	// Half clock cycle at 50 MHz
			// This is the amount of time represented by #1 
timeprecision 1ns;

// These signals are internal because the processor will be 
// instantiated as a submodule in testbench.
logic Clk = 0;
logic Reset, Continue, Run, CE, UB, LB, OE, WE;
logic [15:0]    S;	 
logic[19:0]     ADDR;
logic[11:0]     LED;
logic[6:0]      HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
wire [15:0]     Data;
//logic [15:0] MARout, MDRout, IRout, PCout;
     


//integer ErrorCnt = 0;

lab6_toplevel process(.*);

always begin : CLOCK_GENERATION
#1 Clk = ~Clk;
end		 

initial begin: CLOCK_INITIALIZATION
    Clk = 0;
end 
initial begin: TEST_VECTORS
Reset = 0;		// Toggle Reset
Run = 1;
Continue = 0;

#2	Reset = 1;
#2
#4 S = 16'h0014;
#2
#2 Run = 0;
#2
#2 Run = 1;
#50
#4 S = 16'h0005;
#2
#12 Continue = 1;
#2
#4 Continue = 0;
#2
#12 Continue = 1;

#50
//#10 S = 16'h0003;
#4 S = 16'h0001;
#2
#4 Continue = 0;
#2
#4 Continue = 1;
#50
#4 Continue = 0;
#2
#4 Continue = 1;
/*
#2
#4 Continue = 0;
#2
#4 Continue = 1;
#2
#4 Continue = 0;
#2
#4 Continue = 1;
#2
#4 Continue = 0;
#2
#4 Continue = 1;
#2
#4 Continue = 0;
#2
#4 Continue = 1;
#2
#6 S = 16'h0006;
#2

#4 Continue = 0;
#2
#4 Continue = 1;
#2
#4 Continue = 0;
#2
#4 Continue = 1;

#4 Continue = 0;
#2
#4 Continue = 1;
#2
#4 Continue = 0;
#2
#4 Continue = 1;
#4 Continue = 0;
#2
#4 Continue = 1;
#2
#4 Continue = 0;
#2
#4 Continue = 1;
#4 Continue = 0;
#2
#4 Continue = 1;
#2
#4 Continue = 0;
#2
#4 Continue = 1;
*/
end



endmodule
