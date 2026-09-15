`timescale 1ns/1ps

module xor_gate_tb();
    reg a, b;
    wire c;

    // Instantiate Design Under Test (DUT)
    xor_gate uut (
        .a(a),
        .b(b),
        .c(c)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, xor_gate_tb);

        $display("--- Starting XOR Gate Test ---");
        $monitor("Time=%0t | a=%b, b=%b => c=%b", $time, a, b, c);

        a = 0; b = 0; #20;
        a = 0; b = 1; #20;
        a = 1; b = 0; #20;
        a = 1; b = 1; #20;

        $display("--- XOR Gate Test Finished ---");
        $finish;
    end
endmodule
