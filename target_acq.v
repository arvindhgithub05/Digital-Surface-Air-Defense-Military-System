`timescale 1ns / 1ps

module target_acq (
    input  wire         clk,              // System clock
    input  wire         reset_n,          // Active-low synchronous reset

    input  wire [15:0]  x_in,             // Input X coordinate
    input  wire [15:0]  y_in,             // Input Y coordinate
    input  wire         data_in_valid,    // Input valid
    output wire         data_in_ready,    // Ready to accept next input

    output wire [15:0]  x_out,            // Output X (passed through)
    output wire [15:0]  y_out,            // Output Y (passed through)
    output wire         target_found,     // Asserted when valid target acquired
    output wire         data_out_valid,   // Output valid
    input  wire         data_out_ready    // Downstream ready
);

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    parameter [15:0] TRACK_THRESHOLD = 16'd3;   // Max deviation allowed
    parameter        LOCK_COUNT      = 4;       // Must be stable for 4 samples

    // -------------------------------------------------------------------------
    // Internal registers
    // -------------------------------------------------------------------------
    reg [15:0] prev_x;
    reg [15:0] prev_y;
    reg [15:0] prev_z;

    reg [15:0] x_buffer;
    reg [15:0] y_buffer;
    reg [15:0] z_buffer;

    reg [2:0]  lock_counter;         // Up to 7 (3 bits) — count of stable samples
    reg        buffer_valid;

    reg        target_acquired;

    // -------------------------------------------------------------------------
    // Compute difference (unsigned delta)
    // -------------------------------------------------------------------------
    wire [15:0] delta_x = (x_in > prev_x) ? (x_in - prev_x) : (prev_x - x_in);
    wire [15:0] delta_y = (y_in > prev_y) ? (y_in - prev_y) : (prev_y - y_in);
    wire [15:0] delta_z = (z_in > prev_z) ? (z_in - prev_z) : (prev_z - z_in);

    // -------------------------------------------------------------------------
    // Handshake control
    // -------------------------------------------------------------------------
    assign data_in_ready  = ~buffer_valid;      // Accept new input only if buffer is free
    assign data_out_valid = buffer_valid;
    assign target_found   = target_acquired;

    // -------------------------------------------------------------------------
    // Output assignment
    // -------------------------------------------------------------------------
    assign x_out = x_buffer;
    assign y_out = y_buffer;
    assign z_out = z_buffer;

    // -------------------------------------------------------------------------
    // Target Acquisition Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset all state
            prev_x           <= 16'd0;
            prev_y           <= 16'd0;
            prev_z           <= 16'd0;
            x_buffer         <= 16'd0;
            y_buffer         <= 16'd0;
            z_buffer         <= 16'd0;
            lock_counter     <= 3'd0;
            buffer_valid     <= 1'b0;
            target_acquired  <= 1'b0;
        end else begin
            // Step 1: Accept new coordinate if valid and buffer is free
            if (data_in_valid && ~buffer_valid) begin
                if ((delta_x <= TRACK_THRESHOLD) && (delta_y <= TRACK_THRESHOLD) && (delta_z <= TRACK_THRESHOLD))begin
                    // Movement is within expected range → increment lock counter
                    if (lock_counter < LOCK_COUNT)
                        lock_counter <= lock_counter + 1'b1;

                    // If threshold reached, mark target as acquired
                    if (lock_counter + 1 >= LOCK_COUNT)
                        target_acquired <= 1'b1;
                end else begin
                    // Target jittered or jumped too far → reset counter
                    lock_counter    <= 3'd0;
                    target_acquired <= 1'b0;
                end

                // Store current values as last seen
                prev_x <= x_in;
                prev_y <= y_in;
                prev_z <= z_in;

                // Output buffer stores this sample
                x_buffer     <= x_in;
                y_buffer     <= y_in;
                z_buffer     <= z_in;
                buffer_valid <= 1'b1;
            end

            // Step 2: Downstream accepted the output
            else if (buffer_valid && data_out_ready) begin
                buffer_valid <= 1'b0;
            end
        end
    end

endmodule
