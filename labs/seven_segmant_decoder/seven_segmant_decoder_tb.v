`timescale 1ns/1ps

module seven_segmant_decoder_tb();
    reg [3:0] bcd;
    wire [6:0] seg;
    integer i;

    seven_segmant_decoder dut (
        .bcd(bcd),
        .seg(seg)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, seven_segmant_decoder_tb);

        $display("--- Starting 7-Segment Decoder Test ---");
        $monitor("Time=%0t | BCD=%0d (binary: %b) => Segments(a-g)=%b", $time, bcd, bcd, seg);

        for (i = 0; i <= 10; i = i + 1) begin
            bcd = i;
            #20;
        end

        $display("--- 7-Segment Decoder Test Finished ---");
        $finish;
    end
endmodule
