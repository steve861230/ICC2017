module DT(
	input 			clk, 
	input			reset,
	output	reg		done ,
	output	reg		sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input		[15:0]	sti_di,
	output	reg		res_wr ,
	output	reg		res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input		[7:0]	res_di
	);
///////////////////////////////////////////////////
reg [3:0] counter_sti_index;
reg [13:0] counter_res;
reg [7:0] addr_point;
reg [1:0] counter_load;


//reg fwpass_finish;

///////////////////////////////////////////////////
///////////////////////////////////////////////////
reg [2:0] cur_st, nxt_st;

parameter IDLE = 3'd0,
			READY = 3'd1,
			CHECK_FWP = 3'd2,
			LOAD_FWP = 3'd3,
			FWPASS_FINISH = 3'd4,
			CHECK_BCP = 3'd5,
			LOAD_BCP = 3'd6,
			DONE = 3'd7;
			
			
			
always@(posedge clk or negedge reset)
if(~reset)
	cur_st <= IDLE;
else
	cur_st <= nxt_st;
	
always@(*)
begin
case(cur_st)
	IDLE : nxt_st = READY;
	READY : nxt_st = CHECK_FWP;
	CHECK_FWP : nxt_st = (counter_res==14'd16255)? FWPASS_FINISH : (sti_di[~counter_sti_index])? LOAD_FWP : CHECK_FWP;
	LOAD_FWP : nxt_st = (counter_load==2'd3)? CHECK_FWP : (res_di==0)? CHECK_FWP : LOAD_FWP;
	FWPASS_FINISH : nxt_st = CHECK_BCP;
	CHECK_BCP : nxt_st = (counter_res==14'd8)? DONE : (sti_di[counter_sti_index])? LOAD_BCP : CHECK_BCP;
	LOAD_BCP : nxt_st = (counter_load==2'd0)? CHECK_BCP : (res_di==0)? CHECK_BCP : LOAD_BCP;
	default : nxt_st = DONE;
endcase
end
//////////////////////////////////////////////////
always@(*)
if(cur_st==IDLE)
	sti_rd = 0;
else
	sti_rd = 1;

always@(posedge clk or negedge reset)
if(~reset)
	sti_addr <= 10'd8;
else if(counter_sti_index==4'd15)
	begin
	if(nxt_st==CHECK_FWP)
		sti_addr <= sti_addr + 1;
	else if(nxt_st==CHECK_BCP)
		sti_addr <= sti_addr - 1;
	end
//

always@(posedge clk or negedge reset)
if(~reset)
	counter_sti_index <= 4'd0;
else if((nxt_st==CHECK_FWP)||(nxt_st==FWPASS_FINISH)||(nxt_st==CHECK_BCP))
	counter_sti_index <= counter_sti_index + 1;

	
always@(posedge clk or negedge reset)
if(~reset)
	counter_res <= 14'd128;
else if(nxt_st==CHECK_FWP)
	counter_res <= counter_res + 1;
else if(nxt_st==CHECK_BCP)
	counter_res <= counter_res - 1;

always@(*)
if(cur_st==IDLE || cur_st==LOAD_FWP || cur_st==LOAD_BCP)
	res_rd = 1;
else
	res_rd = 0;

always@(*)
if(cur_st==CHECK_FWP || cur_st==CHECK_BCP)
	res_wr = 1;
else
	res_wr = 0;


always@(posedge clk or negedge reset)
if(~reset)
	res_addr <= 0;
else if(nxt_st==LOAD_FWP)
	res_addr <= counter_res - addr_point;
else if(nxt_st==LOAD_BCP)
	res_addr <= counter_res + addr_point;
else
	res_addr <= counter_res;

/*always@(*)
	res_addr = counter_res - addr_point;
*/
always@(*)
begin
case(counter_load)
	2'd0 : addr_point = 8'd129;
	2'd1 : addr_point = 8'd128;
	2'd2 : addr_point = 8'd127;
default : addr_point = 8'd0;
endcase
end	

always@(posedge clk or negedge reset)
if(~reset)
	counter_load <= 0;
else if(nxt_st==CHECK_FWP || nxt_st==CHECK_BCP)
	counter_load <= 0;
else if(nxt_st==LOAD_FWP || nxt_st==LOAD_BCP)
	counter_load <= counter_load+1;

	
always@(posedge clk or negedge reset)
if(~reset)
	res_do <= 0;
else if(cur_st==LOAD_FWP)
begin
	if(counter_load==2'd3 || res_di==0)begin
		if(res_di<res_do)
			res_do <= res_di+1;
		else
			res_do <= res_do+1;
	end
	else if(res_di<res_do)
	res_do <= res_di;
	
end
else if(cur_st==LOAD_BCP)
begin
	if(res_di==0)
	res_do <= 1;
	else if(counter_load==2'd0)begin
		if(res_di<=res_do)
			res_do <= res_di;
		else
			res_do <= res_do+1;
	end
	else if(res_di<=res_do)
	res_do <= res_di;
	
end
else if((cur_st==CHECK_FWP && nxt_st==CHECK_FWP) || (cur_st==CHECK_BCP && nxt_st==CHECK_BCP))
	res_do <= 0;
	

/*always@(posedge clk or negedge reset)
if(~reset)
	fwpass_finish <= 0;
else if(cur_st==FWPASS_FINISH)
	fwpass_finish <= 1;
else
	fwpass_finish <= 0;
*/	
always@(posedge clk or negedge reset)
if(~reset)
	done <= 0;
else if(cur_st==DONE)
	done <= 1;
else
	done <= 0;
	
endmodule
