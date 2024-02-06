module full_adder (input x,y,z, output logic s,c);
	assign s = x^y^z; // XOR x,y,z and store into s
	assign c = (x&y) | (y&z) | (x&z); // make the full adder
	
endmodule