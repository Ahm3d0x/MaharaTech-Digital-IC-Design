`timescale 1ns/1ps

module frequancy_devider_tb();
    reg clk;
    wire dev_clk;
    wire [6:0] count;

    frequancy_devider dut (
        .clk(clk),
        .dev_clk(dev_clk),
        .count(count)
    );

    always #5 clk = ~clk; // 100MHz clock (10ns period)

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, frequancy_devider_tb);

        clk = 0;
        $display("--- Starting Frequency Divider Test ---");

        // Run for 220 clock cycles to observe count reaching 99 and toggling dev_clk twice
        #2200;

        $display("--- Frequency Divider Test Finished ---");
        $finish;
    end
endmodule
