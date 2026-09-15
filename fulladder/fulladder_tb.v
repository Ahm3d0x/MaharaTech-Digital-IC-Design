`timescale 1ns/1ps

module fulladder_tb();
    reg A, B, C;
    wire S, COUT;

    fulladder adder_dut (
        .a(A),
        .b(B),
        .cin(C),
        .cout(COUT),
        .s(S)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, fulladder_tb);

        $display("--- Starting Full Adder Test ---");
        $monitor("Time=%0t | A=%b B=%b Cin=%b => Sum=%b Cout=%b", $time, A, B, C, S, COUT);

        A=0; B=0; C=0; #20;
        A=0; B=0; C=1; #20;
        A=0; B=1; C=0; #20;
        A=0; B=1; C=1; #20;
        A=1; B=0; C=0; #20;
        A=1; B=0; C=1; #20;
        A=1; B=1; C=0; #20;
        A=1; B=1; C=1; #20;

        $display("--- Full Adder Test Finished ---");
        $finish;
    end
endmodule