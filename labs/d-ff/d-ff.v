
module d_ff (d,clk,reset,q);
input d,clk,reset;
output reg q;
always @(posedge clk or negedge reset)
	if (!reset)
		q <= 0;
	else
		q <= d;
endmodule


