
module counter_using_stat(
input clk,
input reset,
input start,
output reg [3:0] count

);
reg stat;

initial begin count = 4'b0 ;stat = 1'b0; end
always @(posedge clk or posedge reset)begin
	
	if (reset)begin
		count <= 4'b0;
		stat <= 1'b0;
	end else begin
	case (stat)
		1'b0:begin
			count <= 4'b0;
			if(start)begin
				stat <= 1'b1;
			end
		end
		1'b1 : begin
			if(!start)begin//stop or hold
				count <= count;
			end else if (count == 4'd9)begin
				stat <= 1'b0;
				count <= 4'b0;
			end else begin
				count <= count + 4'b1;
			end
		end
		default:stat <= 1'b0;
	endcase
	end
end
endmodule
