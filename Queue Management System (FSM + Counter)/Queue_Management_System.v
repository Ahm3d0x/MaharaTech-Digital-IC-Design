
module Queue_Management_System (
input clk,
input reset,
input sensor_in,
input sensor_out,
input [1:0] active_clerks,

output reg [2:0] queue_count,
output [7:0] wait_time,
output flag_empty,
output flag_full,
output alarm_underflow,
output alarm_overflow,
output [6:0]disp_unit,
output [6:0]disp_tens,
output [6:0]disp_count

);

assign flag_empty = (queue_count == 3'b000);
assign flag_full = (queue_count == 3'b111);

assign alarm_underflow = (flag_empty && sensor_out);
assign alarm_overflow = (flag_full && sensor_in);

always @ (posedge clk or posedge reset) begin
	if (reset)
		queue_count <= 3'b000;
	else begin 
		case({sensor_in,sensor_out})
			2'b10:if(!flag_full)begin queue_count <= queue_count + 1'b1;end
			2'b01:if(!flag_empty)begin queue_count <= queue_count - 1'b1;end
			2'b11: queue_count <= queue_count;
			default : queue_count <= queue_count;
		endcase
	end
end

rom_data get_wait_time(.addr({active_clerks,queue_count}), .data(wait_time));

seven_segmant_decoder unit(.bcd(wait_time[3:0]), .seg(disp_unit));
seven_segmant_decoder tens(.bcd(wait_time[7:4]), .seg(disp_tens));
seven_segmant_decoder count(.bcd({1'b0, queue_count}),.seg(disp_count));
endmodule





