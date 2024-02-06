module carry_select_adder
(
    input   logic[15:0]     A,
    input   logic[15:0]     B,
    output  logic[15:0]     Sum,
    output  logic           CO
);

    /* TODO
     *
     * Insert code here to implement a carry select.
     * Your code should be completly combinational (don't use always_ff or always_latch).
     * Feel free to create sub-modules or other files. */
	  logic c4, c8, c12, c80, c81, c120, c121, c160, c161;
	  logic[3:0] s80, s81, s8, s120, s121, s12, s160, s161, s16;
     
	  fourbit_cra  CRA0 (.A (A[3:0]), .B (B[3:0]), .Ci (0) , .Sum (Sum[3:0]), .CO (c4));
	  
	  
  	  fourbit_cra  CRA1 (.A (A[7:4]), .B (B[7:4]), .Ci (0) , .Sum (s80), .CO (c80));
  	  fourbit_cra  CRA2 (.A (A[7:4]), .B (B[7:4]), .Ci (1) , .Sum (s81), .CO (c81));
	  assign c8 = (c4 & c81) | c80;
	
			
	  fourbit_cra  CRA3 (.A (A[11:8]), .B (B[11:8]), .Ci (0) , .Sum (s120), .CO (c120));
  	  fourbit_cra  CRA4 (.A (A[11:8]), .B (B[11:8]), .Ci (1) , .Sum (s121), .CO (c121));
	  assign c12 = (c8 & c121) | c120;
	    
	  
	  fourbit_cra  CRA5 (.A (A[15:12]), .B (B[15:12]), .Ci (0) , .Sum (s160), .CO (c160));
  	  fourbit_cra  CRA6 (.A (A[15:12]), .B (B[15:12]), .Ci (1) , .Sum (s161), .CO (c161));
	  assign CO = (c12 & c161) | c160;
	 
	  always_comb begin
	  
	  case (c4) 
			1'b0 : Sum[7:4] = s80;
			1'b1 : Sum[7:4] = s81;
	  endcase
	  
	  case (c8) 
			1'b0 : Sum[11:8] = s120;
			1'b1 : Sum[11:8] = s121;
	  endcase	
	  
	  case (c12) 
			1'b0 : Sum[15:12] = s160;
			1'b1 : Sum[15:12] = s161;
	  endcase
	  
	  
	  end
	  
	  
endmodule
