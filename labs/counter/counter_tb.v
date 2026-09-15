`timescale 1ns/1ps

module Johnson_counter_tb();
    reg clk, reset;
    wire [3:0] t_q;

    Johnson_counter Johnson_counter_dut (
        .clk(clk),
        .reset(reset),
        .q(t_q)
    );

    always #10 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, Johnson_counter_tb);

        $display("--- Starting Johnson Counter Test ---");
        $monitor("Time=%0t | reset=%b | Q=%b (%0d)", $time, reset, t_q, t_q);

        clk = 0;
        reset = 0;
        #30 reset = 1;
        #200;

        $display("--- Johnson Counter Test Finished ---");
        $finish;
    end
endmodule
