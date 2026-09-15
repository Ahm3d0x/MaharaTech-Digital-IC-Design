`timescale 1ns/1ps

module keybord_encoder_tb();
    reg [9:1] a;
    wire [3:0] b;

    keybord_encoder keybord_encoder_dut (
        .a(a),
        .b(b)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, keybord_encoder_tb);

        $display("--- Starting Keyboard Encoder Test ---");
        $monitor("Time=%0t | Key Input(9:1)=%b => BCD Output=%b (%0d)", $time, a, b, b);

        a = 9'b000000000; #20;
        a = 9'd1;   #20; // Key 1
        a = 9'd2;   #20; // Key 2
        a = 9'd4;   #20; // Key 3
        a = 9'd8;   #20; // Key 4
        a = 9'd16;  #20; // Key 5
        a = 9'd32;  #20; // Key 6
        a = 9'd64;  #20; // Key 7
        a = 9'd128; #20; // Key 8
        a = 9'd256; #20; // Key 9

        $display("--- Keyboard Encoder Test Finished ---");
        $finish;
    end
endmodule