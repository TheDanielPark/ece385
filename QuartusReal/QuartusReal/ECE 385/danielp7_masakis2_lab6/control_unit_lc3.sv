module control_unit_lc3 (
		input logic Run, Continue, Clk, Reset,

 );

    // Declare signals curr_state, next_state of type enum
    // with enum values of A, B, ..., S as the state values
	 // Changed to 5 bits because we have 19 different states
    enum logic [3:0] {A, B, C, D, E, F, G, H, I, J} curr_state, next_state; 
	//updates flip flop, current state is the only one
    always_ff @ (posedge Clk or posedge Reset)  
    begin
        if (Reset)  
            curr_state <= A;
        else 
            curr_state <= next_state;
    end

    // Assign outputs based on state
	always_comb
   begin
        
		  next_state  = curr_state;	//required because I haven't enumerated all possibilities below
        unique case (curr_state) 

				A :    if (Run) 				//start state
                     next_state = B; //
				B : 	next_state = C;
				C : 	next_state = D;
				D : 	next_state = E;
				E :   next_state = F;
				F : 	next_state = G;
				G : 	next_state = H;
				I : 	next_state = I;
				J :   if (Continue)
							next_state = A;
							
									  
        endcase
	end
		  // Assign outputs based on ‘state’
	always_comb
	begin
		case (curr_state) 
	   	   
					
	   	   // default case to clear out all values
	   	   default:  
		      begin 
				clearA = 1'b0;
				Shift = 1'b0;
				Clr_Ld = 1'b0;
				Sub = 1'b0;
				Add = 1'b0;
		      end 
		endcase
	end

endmodule