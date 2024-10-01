module FSM #(parameter DATA_WIDTH=32)(
	
	input RST,CLK,start,
	input [DATA_WIDTH-1:0] x_vict,y_vict,theta_vict,
	input [DATA_WIDTH-1:0] sin_vict,cos_vict,
	input valid_vict,
	input [DATA_WIDTH-1:0] x_rot,y_rot,
	input valid_rot,
	

	output reg [DATA_WIDTH-1:0] x0_vict,y0_vict,
	output reg start_vict,
	output reg [DATA_WIDTH-1:0] x0_rot,y0_rot,theta_rot,
	output reg start_rot
	
);

	////////////// signals  declaration ///////////
	reg [31:0] theta1,cos_th1,sin_th1;
	reg [31:0] theta2,cos_th2,sin_th2;
	reg [31:0] theta3,cos_th3,sin_th3;


	////////////// matrices declaration ///////////
	reg [31:0]  Q_t   [0:2] [0:2];
	reg [31:0]  R     [0:2] [0:2];
	reg [31:0]  R_inv [0:2] [0:2];
	reg [31:0]  A     [0:2] [0:2]; //result 


	typedef enum logic [3:0] {
		IDLE 		= 4'b0000,
		eliminate_d = 4'b0001,
		calc_be 	= 4'b0011,
		get_be      = 4'b0010,
		calc_cf 	= 4'b0110,
		eliminate_g = 4'b0111,
		calc_bc 	= 4'b0101,
		get_bc		= 4'b0100,
		calc_hi 	= 4'b1100,
		eliminate_h = 4'b1110,
		calc_fi  	= 4'b1111,
		get_fi		= 4'b1011,
		calc_Qt 	= 4'b1001,
		calc_Rinv   = 4'b1101,
		calc_res 	= 4'b1000
	} state_t;


	state_t next_state , curr_state ;

	always@(posedge CLK or negedge RST) begin
		if(!RST)
			next_state<= IDLE;
		else
			next_state <= curr_state;
	end

	
	always@(posedge CLK or negedge RST) begin
	
		case(curr_state)
		IDLE: begin
		
			if(start)
			begin
				next_state<= eliminate_d ;
				start_vict<= 1'b1;
				y0_vict<= R[1][0];  //d
				x0_vict<= R[0][0];  //a
			end
			else next_state<= IDLE ;
		end
		
		
		eliminate_d: begin
		
			if(valid_vict)
			begin
				R[1][0]<= y_vict;  //new d
				R[0][0]<= x_vict;  //new a
				theta1<=theta_vict;
				
				next_state<= calc_be ;
			end
			else next_state<= eliminate_d ;
		end
		
		calc_be: begin
		
				start_rot<= 1'b1;
				x0_rot<= R[0][1]; //b
				y0_rot<= R[1][1]; //e
				theta_rot<= theta1;
				
				start_vict<= 1'b1;
				x0_vict<= theta1;
				next_state<=get_be;
		end
		
		get_be: begin // calculate sin,cos using vict and b,e using rotationa
		
			if(valid_vict && valid_rot)
			begin
			
				sin_th1<= sin_vict;
				cos_th1<= cos_vict;
				
				R[0][1]<=x_rot ; //b
				R[1][1]<=y_rot ; //e
				
				next_state<= calc_cf;
				start_rot<= 1'b1;
				x0_rot<= R[0][2]; //c
				y0_rot<= R[1][2]; //f
				theta_rot<= theta1;
			end
			
			else
				next_state<=get_be;
		end
		
		calc_cf: begin 
		
			if(valid_rot)
			begin
			
				R[0][2]<= x_rot; //c
				R[1][2]<= y_rot; //f
				
				next_state<= eliminate_g;
				start_vict<=1'b1;
				x0_vict<=R[0][0]; //a
				y0_vict<=R[2][0]; //g
			end
			
			else 
				next_state<= calc_cf;
		end
		

		eliminate_g: begin 
		
			if(valid_vict)
			begin
			
				R[0][0]<=x_vict; //a
				R[2][0]<=y_vict; //g
				theta2<=theta_vict;
				
				
				next_state<= calc_bc;
			end
			
			else 
				next_state<= eliminate_g;
		end
		
		calc_bc: begin
		
				start_vict<=1'b1;
				x0_vict<=theta2;  
				
				start_rot<=1'b1;
				x0_rot<=R[0][1]; //b
				y0_rot<=R[0][2]; //c
				theta_rot<=theta2;	
		end
		
		get_bc: begin // calculate sin,cos using vict and b,e using rotationa
		

			if(valid_vict && valid_rot)
			begin
			
				sin_th2<= sin_vict;
				cos_th2<= cos_vict;
				
				R[0][1]<=x_rot ; //b
				R[0][2]<=y_rot ; //c
				
				next_state<= calc_hi;
				start_rot<= 1'b1;
				x0_rot<= R[2][1]; //h
				y0_rot<= R[2][2]; //i
				theta_rot<= theta2;
			end
			
			else
				next_state<=get_bc;
		end
		
		calc_hi: begin
		
			if(valid_rot)
			begin
			
				R[2][1]<=x_rot; //h
				R[2][2]<=y_rot; //i

				next_state<= eliminate_h;
				start_vict<=1'b1;
				x0_vict<=R[1][1]; //e
				y0_vict<=R[2][1]; //h
			end
			else
				next_state<= calc_hi;
		end
		
		eliminate_h : begin
			if(valid_vict)
			begin
			
				R[1][1]<=x_rot; //e
				R[2][1]<=y_rot; //h
				theta3 <= theta_vict;
				
				next_state<= calc_fi;
			end
			else
				next_state<=eliminate_h;
		end
		
		calc_fi: begin

			start_rot<=1'b1;
			x0_rot<=R[1][2]; //f
			y0_rot<=R[2][2]; //i
			theta_rot<= theta3;
			
			start_vict<=1'b1;
			x0_vict<=theta3;
			next_state<=get_fi;
		end
		
		get_fi: begin // calculate sin,cos using vict and b,e using rotationa
		
			if(valid_vict && valid_rot)
			begin
			
				sin_th3<= sin_vict;
				cos_th3<= cos_vict;
				
				R[1][2]<=x_rot ; //f
				R[2][2]<=y_rot ; //i
				
				next_state<=calc_Qt;
			end
			else
				next_state<=get_fi;
		end
		
		calc_Qt: begin
		
			Qt();
			next_state<= calc_Rinv;
		end
		
		calc_Rinv: begin
		
			c_Rinv();
			next_state<= calc_res;
		end
		
		calc_res: begin
		
			Result();
			next_state<= IDLE;
			
		end
	
		endcase
	end
	function Qt();
	
		Q_t[0][0] =     cos_th1;
		Q_t[0][1] = 	-sin_th1*cos_th2;
		Q_t[0][2] = 	-sin_th2;
		Q_t[1][0] = 	cos_th3*(sin_th1+ (sin_th2*cos_th1));
		Q_t[1][1] = 	cos_th3*(cos_th1- (sin_th1*sin_th2) );
		Q_t[1][2] = 	cos_th2*cos_th3 - sin_th3;
		Q_t[2][0] = 	sin_th3*( (cos_th1*sin_th2) + sin_th1);
		Q_t[2][1] = 	sin_th3*(cos_th1 - (sin_th1*sin_th2) );
		Q_t[2][2] = 	cos_th3 + (sin_th3*cos_th2);
		
	endfunction
	
	function c_Rinv();
		
		R_inv[1][0] = 	'd0;
		R_inv[2][0] = 	'd0;
		R_inv[2][1] = 	'd0;
		
		R_inv[0][0] =   1/R[0][0];
		R_inv[0][1] = 	-R[0][1]/(R[0][0]*R[1][1]);
		R_inv[0][2] = 	(R[0][1]*R[1][2]-R[0][2]*R[1][1])/(R[0][0]*R[1][1]*R[2][2]);
		R_inv[1][1] = 	1/R[1][1];
		R_inv[1][2] = 	-R[1][2]/(R[1][1]*R[2][2]);
		R_inv[2][2] = 	1/R[2][2];
		
	endfunction
	
	function Result();
		
		A[0][0] =   'd0;
		A[0][1] = 	'd0;
		A[0][2] = 	'd0;
		A[1][0] = 	'd0;
		A[1][1] = 	'd0;
		A[1][2] = 	'd0;
		A[2][0] = 	'd0;
		A[2][1] = 	'd0;
		A[2][2] = 	'd0;
		
	endfunction

endmodule
