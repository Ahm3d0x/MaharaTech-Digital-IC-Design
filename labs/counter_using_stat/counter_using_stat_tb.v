`timescale 1ns/1ps

module counter_using_stat_tb();
    reg clk, reset, start;
    wire [3:0] count;

    counter_using_stat dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .count(count)
    );

    always #10 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, counter_using_stat_tb);

        $display("--- Starting FSM State Counter Test ---");
        $monitor("Time=%0t | reset=%b | start=%b | count=%0d", $time, reset, start, count);

        clk = 0;
        reset = 1;
        start = 0;

        #25 reset = 0;
        #20 start = 1;

        // Run until counter finishes 0-9 and returns to idle
        #240;

        // Stop start to test hold / idle
        start = 0;
        #40;

        // Start again
        start = 1;
        #100;

        $display("--- FSM State Counter Test Finished ---");
        $finish;
    end
endmodule
