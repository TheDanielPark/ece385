module testbench_mult();


timeunit 10ns;	// Half clock cycle at 50 MHz
			// This is the amount of time represented by #1 
timeprecision 1ns;

// These signals are internal because the processor will be 
// instantiated as a submodule in testbench.
logic Clk = 0;
logic Reset, ClearA_LoadB, Run;
logic [7:0] Din;	 
logic  X;
logic[7:0]      Aval;
logic[7:0]      Bval;
logic[6:0]      AhexU;      
logic[6:0]      AhexL;
logic[6:0]      BhexU;
logic[6:0]      BhexL;

//integer ErrorCnt = 0;

Processor process(.*);

always begin : CLOCK_GENERATION
#1 Clk = ~Clk;
end		 

initial begin: CLOCK_INITIALIZATION
    Clk = 0;
end 
initial begin: TEST_VECTORS
Reset = 0;		// Toggle Reset
Run = 1;
// - * -
#2 Reset = 1;	

#2


#2 Din = 8'hff;	// Setting Din

#2

#2 ClearA_LoadB = 0;

#2

#2 ClearA_LoadB = 1;
#2 

#2	Din = 8'hff;
	
#2

#2 Run = 0;

#2

#40 Run  = 1;

// new
#4
Reset = 0;		// Toggle Reset
Run = 1;
// + * -
#2 Reset = 1;	

#2


#2 Din = 8'h02;	// Setting Din

#2

#2 ClearA_LoadB = 0;

#2

#2 ClearA_LoadB = 1;
#2 

#2	Din = 8'hff;
	
#2

#2 Run = 0;

#2

#40 Run  = 1;


// new

#4
Reset = 0;		// Toggle Reset
Run = 1;
// - * +
#2 Reset = 1;	

#2


#2 Din = 8'hff;	// Setting Din

#2

#2 ClearA_LoadB = 0;

#2

#2 ClearA_LoadB = 1;
#2 

#2	Din = 8'h02;
	
#2

#2 Run = 0;

#2

#40 Run  = 1;



//new

#4
Reset = 0;		// Toggle Reset
Run = 1;
// + * +
#2 Reset = 1;	

#2


#2 Din = 8'h02;	// Setting Din

#2

#2 ClearA_LoadB = 0;

#2

#2 ClearA_LoadB = 1;
#2 

#2	Din = 8'h03;
	
#2

#2 Run = 0;

#2

#40 Run  = 1;



end	 
endmodule
