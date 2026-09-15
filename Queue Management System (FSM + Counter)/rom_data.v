module rom_data (
    input [4:0] addr,
    output reg [7:0] data
);
    wire [1:0] active_clerks = addr[4:3];
    wire [2:0] queue_count   = addr[2:0];

    integer wait_mins;
    integer tens;
    integer units;

    always @(*) begin
        if (active_clerks == 2'b00 || queue_count == 3'b000) begin
            wait_mins = 0;
        end else begin
            // Estimated average: 4 minutes per customer divided by active clerks
            wait_mins = (queue_count * 4) / active_clerks;
        end
        tens = (wait_mins / 10) % 10;
        units = wait_mins % 10;
        data = {tens[3:0], units[3:0]};
    end
endmodule
