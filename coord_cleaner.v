`timescale 1ns / 1ps

module coord_cleaner (
    input  wire         clk,            // System clock
    input  wire         reset_n,        // Active-low synchronous reset

    input  wire [15:0]  x_in,           // Input X coordinate from parser
    input  wire [15:0]  y_in,           // Input Y coordinate from parser
    input  wire [15:0]  z_in,           // Input Z coordinate from parser
    input  wire         data_in_valid,  // Asserted when new input data is valid
    output wire         data_in_ready,  // Cleaner is ready to accept new data

    output wire [15:0]  x_out,          // Cleaned output X coordinate
    output wire [15:0]  y_out,          // Cleaned output Y coordinate
    output wire [15:0]  z_out,          // Cleaned output Z coordinate
    output wire         data_out_valid, // Asserted when output data is valid
    input  wire         data_out_ready  // Next module ready to accept data
);   
    // -------------------------------------------------------------------------
    // Parameters for noise threshold
    // -------------------------------------------------------------------------
    parameter [15:0] THRESHOLD_X = 16'd4;
    parameter [15:0] THRESHOLD_Y = 16'd4;
    parameter [15:0] THRESHOLD_Z = 16'd4;

    // -------------------------------------------------------------------------
    // Internal registers to store previous coordinate and output buffer
    // -------------------------------------------------------------------------
    reg [15:0] prev_x;
    reg [15:0] prev_y;
    reg [15:0] prev_z;

    reg [15:0] x_buffer;
    reg [15:0] y_buffer;
    reg [15:0] z_buffer;
    reg        buffer_valid;  // To make sure the buffer is ready to receive data

    // -------------------------------------------------------------------------
    // Delta computation wires (unsigned difference)
    // -------------------------------------------------------------------------
    wire [15:0] delta_x = (x_in > prev_x) ? (x_in - prev_x) : (prev_x - x_in);
    wire [15:0] delta_y = (y_in > prev_y) ? (y_in - prev_y) : (prev_y - y_in);
    wire [15:0] delta_z = (z_in > prev_z) ? (z_in - prev_z) : (prev_z - z_in);

    // -------------------------------------------------------------------------
    // Input ready signal: can only accept if buffer is empty
    // -------------------------------------------------------------------------
    assign data_in_ready = ~buffer_valid;

    // -------------------------------------------------------------------------
    // Sequential logic: coordinate filtering with flow control
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset all internal registers
            prev_x       <= 16'd0;
            prev_y       <= 16'd0;
	    prev_z       <= 16'd0;
            x_buffer     <= 16'd0;
            y_buffer     <= 16'd0;
            z_buffer     <= 16'd0;
            buffer_valid <= 1'b0;
        end else begin
            // Case 1: Accept new data if valid and buffer is empty
            if (data_in_valid && ~buffer_valid) begin
                if ((delta_x <= THRESHOLD_X) && (delta_y <= THRESHOLD_Y) && (delta_z <= THRESHOLD_Z)) begin
                    // If within threshold: pass it through
                    x_buffer     <= x_in;
                    y_buffer     <= y_in;
                    z_buffer     <= z_in;
                    buffer_valid <= 1'b1;

                    // Update previous values only if passed
                    prev_x       <= x_in;
                    prev_y       <= y_in;
		            prev_z       <= z_in;
                end
                else begin
		            x_in = prev_x;
		            y_in = prev_y;
		            z_in = prev_z;
		        end
            end
            // Case 2: Output accepted by downstream
            else if (buffer_valid && data_out_ready) begin
                buffer_valid <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------------------------
    assign x_out          = x_buffer;
    assign y_out          = y_buffer;
    assign z_out          = z_buffer;
    assign data_out_valid = buffer_valid;

endmodule