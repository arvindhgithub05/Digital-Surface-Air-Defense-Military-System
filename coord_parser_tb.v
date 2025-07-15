`timescale 1ns / 1ps

module coord_parser_tb;

    // Inputs
    reg clk;
    reg reset_n;
    reg [47:0] data_in;
    reg data_in_valid;
    reg data_ready;

    // Outputs
    wire [15:0] x_coord;
    wire [15:0] y_coord;
    wire [15:0] z_coord;
    wire data_valid;

    // Instantiate the Unit Under Test (UUT)
    coord_parser uut (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(data_in),
        .data_in_valid(data_in_valid),
        .x_coord(x_coord),
        .y_coord(y_coord),
        .z_coord(z_coord),
        .data_valid(data_valid),
        .data_ready(data_ready)
    );

    // Clock generation (period = 10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // Send coordinate task (1-cycle pulse on data_in_valid)
    task send_coord(input [15:0] x, input [15:0] y, input [15:0] z);
        begin
            @(posedge clk);
            data_in       <= {x, y, z};
            data_in_valid <= 1;
            @(posedge clk);
            data_in_valid <= 0;
        end
    endtask

    initial begin
        // Initialize all signals
        data_in       = 0;
        data_in_valid = 0;
        data_ready    = 0;
        reset_n       = 0;

        // Apply reset
        @(posedge clk);
        @(posedge clk);
        reset_n <= 1;

        // Wait a cycle after reset
        @(posedge clk);

        // Send first coordinate
        send_coord(16'd10, 16'd20, 16'd30);
        wait (data_valid == 1);
        @(posedge clk);
        data_ready <= 1; // Simulate consumer ready to accept
        @(posedge clk);
        data_ready <= 0;

        // Send second coordinate
        send_coord(16'd15, 16'd25, 16'd35);
        wait (data_valid == 1);
        @(posedge clk);
        data_ready <= 1;
        @(posedge clk);
        data_ready <= 0;

        // Send third coordinate
        send_coord(16'd1023, 16'd511, 16'd255);
        wait (data_valid == 1);
        @(posedge clk);
        data_ready <= 1;
        @(posedge clk);
        data_ready <= 0;

        // Wait before finish
        #50;
        $finish;
    end

    // Monitor the output
    initial begin
        $display("Time\t\tValid\tX\t\tY\t\tZ");
        $monitor("%0t\t%b\t%h\t%h\t%h", $time, data_valid, x_coord, y_coord, z_coord);
    end

endmodule