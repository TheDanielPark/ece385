module control_unit (
		input logic Clk, Reset, Run, ClearA_LoadB, MShift,
		output logic Clr_Ld, Shift, Add, Sub, clearA

 );

    // Declare signals curr_state, next_state of type enum
    // with enum values of A, B, ..., S as the state values
	 // Changed to 5 bits because we have 19 different states
    enum logic [4:0] {A, B, C, D, E, F, G, H, I , J, K, L, M, N, O, P, Q, R, S}   curr_state, next_state; 

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
			//We made 19 states, 1 to run, 1 to clear A, then 16 for the steps of multiplication, then the finish step.
            A :    if (Run) 				//start state
                     next_state = B; //Go to the clearA/LoadB state
							 
            B :   // if (MShift) begin
							next_state = C; //if M is 1, go to add
					//	 end else begin
					//			next_state = D; //if M is 0, go to shift state
					//			end
            C :      next_state = D;		 //After add go to shift
            D : //   if (MShift) begin
							next_state = E;    //if M is 1, go to add 
					//	end else begin
					//		next_state = F;	 //if M is 0, go to shift state
					//		end
            E :      next_state = F;		 //Add state
            F :  //  if (MShift)	begin				
							next_state = G;	 //if M is 1, go to add 
					//	end else begin
					//		next_state = H;	 //if M is 0, go to shift state
					//		end
				G :	   next_state = H;		 //add state
				H ://	 if (MShift) begin
							next_state = I;	 //if M is 1, go to add
					//	end else begin
					//		next_state = J;	 //if M is 0, go to shift
					//		end
				I :	   next_state = J;		 //Add state
				J ://	 if (MShift) begin
							next_state = K; 	 //if M is 1, go to add
					//	end else begin
					//		next_state = L; 	 //if M is 0, go to shift
					//		end
				K :	   next_state = L;		 //Add state
				L ://	 if (MShift) begin
							next_state = M;	 //if M is 1, go to add
					//	end else begin
					//		next_state = N;	 //if M is 0, go to shift
					//		end
				M : 	   next_state = N;		 //Add state
				N ://	 if (MShift) begin
							next_state = O;	 //if M is 1, go to add
					//	end else begin
					//		next_state = P;	 //if M is 0, go to shift
					//		end
				O : 		next_state = P;		 //Add state
				P : //	 if (MShift) begin
							next_state = Q;	 //if M is 1, go to subtract
					//	end else begin
					//		next_state = R; 	 //if M is 0, go to shift
					//		end
				Q :		next_state = R;		 //Subtract State
				R :	   next_state = S;	 //go to end of program
				S :	if (~Run) 
                     next_state = A;
							  
        endcase
	end
		  // Assign outputs based on ‘state’
	always_comb
	begin
		case (curr_state) 
	   	   A: //In A, we set clear load to 1 or 0 based on clearA_loadB value. The rest are set to 0
	         begin
				Shift = 1'b0;
				Add = 1'b0;
				Sub = 1'b0;
				clearA = 1'b0;
					 if (ClearA_LoadB)
							Clr_Ld = 1'b1;
					 else
							Clr_Ld = 1'b0;
		      end
				B: //set all to 0 but clearA to make sure it clears even if we do multiplication multiple times
				begin
					clearA = 1'b1;
					
					Shift = 1'b0;
					Clr_Ld = 1'b0;
					Sub = 1'b0;
					Add = 1'b0;
				end
				C, E, G, I, K, M, O: 
				begin //Set Add to 1 or 0 based on M value
				Shift = 1'b0;
				Clr_Ld = 1'b0;
				Sub = 1'b0;
				clearA = 1'b0;

					if (MShift) 
						Add = 1'b1;		//Set add to 1
					else 
						Add = 1'b0;
				end
				D, F, H, J, L, N, P, R:
				begin //Set shift high and the rest low to shift the data
					Add = 1'b0;
					Clr_Ld = 1'b0;
					Sub = 1'b0;
					Shift = 1'b1;  //Setting shift to 1
					clearA = 1'b0;

				end
				
				Q: 
				begin //Set add and subtract to high or low based on M value
				Shift = 1'b0;
				Clr_Ld = 1'b0;
				clearA = 1'b0;

					if (MShift)
						Add = 1'b1;
					else
						Add = 1'b0;
					if (MShift) 
						Sub = 1'b1;		//Set add to 1
					else 
						Sub = 1'b0;
				end
				/*
				E: 
				begin
					if (MShift) 
						Add <= 1'b1;		//Set add to 1
					else 
						Add <= 1'b0;
				end
				F:
				begin
					Shift <= 1'b1;
				end
				G: 
				begin
					if (MShift) 
						Add <= 1'b1;		//Set add to 1
					else 
						Add <= 1'b0;
				end
				H:
				begin
					Shift <= 1'b1;
				end
				I: 
				begin
					if (MShift) 
						Add <= 1'b1;		//Set add to 1
					else 
						Add <= 1'b0;
				end
				J:
				begin
					Shift <= 1'b1;
				end
				K: 
				begin
					if (MShift) 
						Add <= 1'b1;		//Set add to 1
					else 
						Add <= 1'b0;
				end
				L:
				begin
					Shift <= 1'b1;
				end
				M: 
				begin
					if (MShift) 
						Add <= 1'b1;		//Set add to 1
					else 
						Add <= 1'b0;
				end
				N:
				begin
					Shift <= 1'b1;
				end
				O: 
				begin
					if (MShift) 
						Add <= 1'b1;		//Set add to 1
					else 
						Add <= 1'b0;
				end
				P:
				begin
					Shift <= 1'b1;
				end
				*/
				
		/*		R:
				begin
					Shift <= 1'b1;
				end
				S: 
				begin
					
				end 
				
				
			*/
					
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