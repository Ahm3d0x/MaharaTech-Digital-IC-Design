`timescale 1ns/1ps

module Queue_Management_System_tb();
    reg clk;
    reg reset;
    reg sensor_in;
    reg sensor_out;
    reg [1:0] active_clerks;

    wire [2:0] queue_count;
    wire [7:0] wait_time;
    wire flag_empty;
    wire flag_full;
    wire alarm_underflow;
    wire alarm_overflow;
    wire [6:0] disp_unit;
    wire [6:0] disp_tens;
    wire [6:0] disp_count;

    Queue_Management_System dut (
        .clk(clk),
        .reset(reset),
        .sensor_in(sensor_in),
        .sensor_out(sensor_out),
        .active_clerks(active_clerks),
        .queue_count(queue_count),
        .wait_time(wait_time),
        .flag_empty(flag_empty),
        .flag_full(flag_full),
        .alarm_underflow(alarm_underflow),
        .alarm_overflow(alarm_overflow),
        .disp_unit(disp_unit),
        .disp_tens(disp_tens),
        .disp_count(disp_count)
    );

    always #10 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, Queue_Management_System_tb);

        $display("--- Starting Queue Management System Test ---");
        $monitor("Time=%0t | In=%b Out=%b Clerks=%0d | Count=%0d Empty=%b Full=%b | WaitTime(BCD)=%h | Alarms(OV/UN)=%b/%b",
                 $time, sensor_in, sensor_out, active_clerks, queue_count, flag_empty, flag_full, wait_time, alarm_overflow, alarm_underflow);

        clk = 0;
        reset = 1;
        sensor_in = 0;
        sensor_out = 0;
        active_clerks = 2'd1;

        #25 reset = 0;

        // Test underflow alarm: sensor_out when queue is empty
        #10 sensor_out = 1;
        #20 sensor_out = 0;

        // Customers arriving: increment queue count from 0 up to 7 (full)
        active_clerks = 2'd2;
        repeat (7) begin
            #20 sensor_in = 1;
            #20 sensor_in = 0;
        end

        // Test overflow alarm: sensor_in when queue is full
        #20 sensor_in = 1;
        #20 sensor_in = 0;

        // Change clerks to 1 and observe wait time increase
        #20 active_clerks = 2'd1;

        // Customers departing: decrement queue
        repeat (4) begin
            #20 sensor_out = 1;
            #20 sensor_out = 0;
        end

        #40;
        $display("--- Queue Management System Test Finished ---");
        $finish;
    end
endmodule
