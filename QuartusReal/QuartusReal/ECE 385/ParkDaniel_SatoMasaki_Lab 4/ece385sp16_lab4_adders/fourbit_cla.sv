module fourbit_cla (
			input logic [3:0] A,
			input logic [3:0] B,
			input logic Ci,
			output logic [3:0] Sum,
			output logic CO,
			output logic G,
			output logic P
			);
			
	logic p0, p1, p2, p3, g0, g1, g2, g3, c1, c2, c3;
	assign p0 = A[0] ^ B[0];
	assign g0 = A[0] & B[0]; 

	assign p1 = A[1] ^ B[1];
	assign g1 = A[1] & B[1]; 

	assign p2 = A[2] ^ B[2];
	assign g2 = A[2] & B[2]; 

	assign p3 = A[3] ^ B[3];
	assign g3 = A[3] & B[3]; 

	assign c1 = Ci & p0 | g0;
	assign c2 = (Ci & p0 & p1) | (g0 & p1) | g1;
	assign c3 = (Ci & p0 & p1 & p2) | (g0 & p1 & p2) | (g1 & p2) | g2;

	assign P = p0 & p1 & p2 & p3;
	assign G = g3 | (g2 & p3) | (g1 & p3 & p2) | (g0 & p3 & p2 & p1);

	  full_adder 	FA0 (.x(A[0]), .y(B[0]), .z (Ci), .s (Sum[0]), .c ());
	  full_adder 	FA1 (.x(A[1]), .y(B[1]), .z (c1), .s (Sum[1]), .c ());
	  full_adder 	FA2 (.x(A[2]), .y(B[2]), .z (c2), .s (Sum[2]), .c ());
	  full_adder 	FA3 (.x(A[3]), .y(B[3]), .z (c3), .s (Sum[3]), .c (CO));

endmodule
