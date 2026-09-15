`timescale 1ns/1ps

module kepad_to_3display_tb();
    reg [9:1] keypad_tb;
    reg [1:0] sel_tb;
    reg clk_tb, rst_tb;
    wire [3:0] bcd_bus;
    wire [6:0] r1seg, r2seg, r3seg;

    keybord_encoder keybord_encoder_dut (
        .keypad(keypad_tb),
        .encoder_out(bcd_bus)
    );

    kepad_to_3display kepad_to_3display_dut (
        .sel(sel_tb),
        .encoder_out(bcd_bus),
        .room1seg(r1seg),
        .room2seg(r2seg),
        .room3seg(r3seg),
        .clk(clk_tb),
        .rst(rst_tb)
    );

    always #5 clk_tb = ~clk_tb;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, kepad_to_3display_tb);

        $display("--- Starting Keypad to 3 Display Test ---");
        $monitor("Time=%0t | sel=%b | key=%b | bcd=%b => Room1=%b, Room2=%b, Room3=%b",
                 $time, sel_tb, keypad_tb, bcd_bus, r1seg, r2seg, r3seg);

        clk_tb = 0;
        rst_tb = 1;
        sel_tb = 2'b00;
        keypad_tb = 9'b0;

        #15 rst_tb = 0;
        #20 keypad_tb = 9'd1;   sel_tb = 2'b00; // Room 1 = 1
        #20 keypad_tb = 9'd2;   sel_tb = 2'b01; // Room 2 = 2
        #20 keypad_tb = 9'd4;   sel_tb = 2'b10; // Room 3 = 3
        #20 keypad_tb = 9'd16;  sel_tb = 2'b00; // Room 1 = 5
        #20 keypad_tb = 9'd64;  sel_tb = 2'b01; // Room 2 = 7
        #20 keypad_tb = 9'd256; sel_tb = 2'b10; // Room 3 = 9
        #30;

        $display("--- Keypad to 3 Display Test Finished ---");
        $finish;
    end
endmodule