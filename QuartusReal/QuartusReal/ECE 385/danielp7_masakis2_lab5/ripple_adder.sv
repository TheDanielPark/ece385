module ripple_adder
(
    input   logic[7:0]     A,
    input   logic[7:0]     B,
	 input sub,
    output  logic[7:0]     Sum,
    output  logic           X // make 4 variables, register A,B,
);



     logic c0, c1, c2, c3, c4, c5, c6 ,c7, cin, s8, s10 ;
	  //Set the subtraction value
	  logic [7:0] BSub;
	  //Flip the B bits if subtract is high
	  assign BSub = (B ^ {8{sub}});
	  //Set X to the MSB of A
	  //assign X = A[7] ^ B[7] ^ s8;
	  //Set cin to the subtraction value to carry in 1 if it is subtraction
	  assign cin = sub;
	  //Run the full adder to get the correct values
	  
	  full_adder 	FA0 (.x(A[0]), .y(BSub[0]), .z (cin), .s (Sum[0]), .c (c0));
  	  full_adder 	FA1 (.x(A[1]), .y(BSub[1]), .z (c0), .s (Sum[1]), .c (c1));
	  full_adder 	FA2 (.x(A[2]), .y(BSub[2]), .z (c1), .s (Sum[2]), .c (c2));
	  full_adder 	FA3 (.x(A[3]), .y(BSub[3]), .z (c2), .s (Sum[3]), .c (c3));
	  full_adder 	FA4 (.x(A[4]), .y(BSub[4]), .z (c3), .s (Sum[4]), .c (c4));
	  full_adder 	FA5 (.x(A[5]), .y(BSub[5]), .z (c4), .s (Sum[5]), .c (c5));
	  full_adder 	FA6 (.x(A[6]), .y(BSub[6]), .z (c5), .s (Sum[6]), .c (c6));
	  full_adder 	FA7 (.x(A[7]), .y(BSub[7]), .z (c6), .s (Sum[7]), .c (c7));
	  full_adder 	FA8 (.x(A[7]), .y(BSub[7]), .z (c7), .s (X), .c (s8));
	  

	  
endmodule