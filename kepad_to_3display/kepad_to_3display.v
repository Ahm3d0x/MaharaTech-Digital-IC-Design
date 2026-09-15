module kepad_to_3display(sel,encoder_out,room1seg,room2seg,room3seg,clk,rst);
reg [3:0] reg_room1, reg_room2, reg_room3;
output [6:0] room1seg,room2seg,room3seg;
input [1:0]sel;
input clk,rst;
input [3:0]encoder_out;

	always @(posedge clk or posedge rst)
		if (rst)begin
			reg_room1 <=4'b0; reg_room2 <=4'b0; reg_room3 <=4'b0;
		end else begin
		case (sel)
			2'b00: reg_room1 <= encoder_out ;
			2'b01: reg_room2 <= encoder_out ;
			2'b10: reg_room3 <= encoder_out ;
			default: ;
       		endcase
		end
	seven_segmant_decoder display1(reg_room1,room1seg);
	seven_segmant_decoder display2(reg_room2,room2seg);
	seven_segmant_decoder display3(reg_room3,room3seg);

endmodule

module seven_segmant_decoder (bcd,seg);
input [3:0] bcd;
output reg [6:0] seg;
always @(*)
	begin
		case (bcd)
			4'd0: seg = 7'b0111111;
           		4'd1: seg = 7'b0000110;
            		4'd2: seg = 7'b1011011; 
            		4'd3: seg = 7'b1001111; 
            		4'd4: seg = 7'b1100110;
            		4'd5: seg = 7'b1101101; 
            		4'd6: seg = 7'b1111101;
            		4'd7: seg = 7'b0000111;
			4'd8: seg = 7'b1111111; 
			4'd9: seg = 7'b1101111;
            		default: seg = 7'b0000000; 
       		endcase
	end
endmodule

module keybord_encoder(keypad,encoder_out);
input  [9:1] keypad;
output [3:0] encoder_out;
	assign encoder_out[0] = keypad[1] | keypad[3] | keypad[5] | keypad[7] | keypad[9];
	assign encoder_out[1] = keypad[2] | keypad[3] | keypad[6] | keypad[7];
	assign encoder_out[2] = keypad[4] | keypad[5] | keypad[6] | keypad[7];
	assign encoder_out[3] = keypad[8] | keypad[9];
endmodule

