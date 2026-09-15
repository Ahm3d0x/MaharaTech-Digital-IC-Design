module counter(clk,reset,unit,tens);
input clk,reset;
output [3:0]unit,tens ;
reg [3:0] unit,tens;
 
always @(posedge clk or posedge reset) begin
	if (reset )begin
		unit<=4'd0;
		tens<=4'd0;
	end else begin 
		if(unit ==4'd9&&tens==4'd9)begin
			unit<=4'd0;
			tens<=4'd0;
		end else if(unit ==4'd9) begin 
			unit<=4'd0; 
			tens<= tens +1'b1;
		end  else  begin
			unit <= unit+1'b1;
		end 
	end
end		
endmodule


