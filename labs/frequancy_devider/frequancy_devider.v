module frequancy_devider(clk,dev_clk,count);
input clk;
output reg dev_clk;
output reg [6:0]count;

initial begin dev_clk = 0 ; count = 7'd0; end
always @(posedge clk) begin
	if (count == 7'd99 )begin
		count<=7'd0;
		dev_clk <= ~dev_clk;
	end else begin
        	count   <= count + 1'b1;
    	
	end
end		
endmodule
