`timescale 1ns/1ps

module counter_1_99_tb();
    reg clk, reset;
    wire [3:0] unit, tens;

    counter dut (
        .clk(clk),
        .reset(reset),
        .unit(unit),
        .tens(tens)
    );

    always #10 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, counter_1_99_tb);

        $display("--- Starting 1-99 Counter Test ---");
        $monitor("Time=%0t | reset=%b | Tens=%0d, Unit=%0d (Value=%0d%0d)", $time, reset, tens, unit, tens, unit);

        clk = 0;
        reset = 1;
        #25 reset = 0;

        // Run for 35 clock cycles to see unit rollover and tens incrementing
        #700;

        $display("--- 1-99 Counter Test Finished ---");
        $finish;
    end
endmodule
