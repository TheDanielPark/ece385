module fourbit_cra ( 
	 input   logic[3:0]     A,
    input   logic[3:0]     B,
	 input logic Ci,
    output  logic[3:0]     Sum,
    output  logic           CO
);

     logic c0, c1, c2, c3;
	  
	  full_adder 	FA0 (.x(A[0]), .y(B[0]), .z (Ci), .s (Sum[0]), .c (c0));
  	  full_adder 	FA1 (.x(A[1]), .y(B[1]), .z (c0), .s (Sum[1]), .c (c1));
	  full_adder 	FA2 (.x(A[2]), .y(B[2]), .z (c1), .s (Sum[2]), .c (c2));
	  full_adder 	FA3 (.x(A[3]), .y(B[3]), .z (c2), .s (Sum[3]), .c (CO));
	  
endmodule