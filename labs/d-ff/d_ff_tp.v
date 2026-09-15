`timescale 1ns/1ps

module d_ff_tb();
    reg d, clk, reset;
    wire q;

    d_ff d_ff_dut (
        .d(d),
        .clk(clk),
        .reset(reset),
        .q(q)
    );

    always #10 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, d_ff_tb);

        $display("--- Starting D-FF Test ---");
        $monitor("Time=%0t | reset=%b | clk=%b | D=%b => Q=%b", $time, reset, clk, d, q);

        reset = 0; clk = 0; d = 0;
        #20 reset = 1; d = 1;
        #5  reset = 0; d = 1;
        #10 reset = 1; d = 0;
        #20 reset = 1; d = 1;
        #20 reset = 1; d = 0;
        #20 reset = 1; d = 1;
        #20 reset = 0; d = 1;
        #20 reset = 1; d = 1;
        #30;

        $display("--- D-FF Test Finished ---");
        $finish;
    end
endmodule
