`timescale 1ns/1ps

module orgate_tb();
    reg x, y;
    wire z;

    orgate orgate_dut (
        .a(x),
        .b(y),
        .c(z)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, orgate_tb);

        $display("--- Starting OR Gate Test ---");
        $monitor("Time=%0t | x=%b, y=%b => z=%b", $time, x, y, z);

        x = 0; y = 0; #20;
        x = 0; y = 1; #20;
        x = 1; y = 0; #20;
        x = 1; y = 1; #20;

        $display("--- OR Gate Test Finished ---");
        $finish;
    end
endmodule