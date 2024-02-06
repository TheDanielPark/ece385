module carry_lookahead_adder
(
    input   logic[15:0]     A,
    input   logic[15:0]     B,
    output  logic[15:0]     Sum,
    output  logic           CO
);

    /* TODO
     *
     * Insert code here to implement a CLA adder.
     * Your code should be completly combinational (don't use always_ff or always_latch).
     * Feel free to create sub-modules or other files. */
     
	  logic  g0, g4, g8, g12, p0, p4, p8 ,p12, c4, c8, c12;
	  

	  fourbit_cla  FB0 (.A (A[3:0]), .B (B[3:0]), .Ci (0), .Sum (Sum[3:0]), .CO (), .G (g0), .P (p0));
	  assign c4 = g0 | (0 & p0);
	  
	  fourbit_cla  FB1 (.A (A[7:4]), .B (B[7:4]), .Ci (c4), .Sum (Sum[7:4]), .CO (), .G (g4), .P (p4));
	  assign c8 = g4 | (g0 & p4) | (0 & p0 & p4);
	  
	  fourbit_cla  FB2 (.A (A[11:8]), .B (B[11:8]), .Ci (c8), .Sum (Sum[11:8]), .CO (), .G (g8), .P (p8));
	  assign c12 = g8 | (g4 & p8) | (g0 & p8 & p4) | (0 & p8 & p4 & p0);
	  
	  fourbit_cla  FB3 (.A (A[15:12]), .B (B[15:12]), .Ci (c12), .Sum (Sum[15:12]), .CO (CO), .G (g12), .P (p12));
	  
	  
	  
endmodule
