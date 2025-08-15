`timescale 1ps/1ps

module tracker_core (
    input  wire         clk,
    input  wire         reset_n,

    input  wire         lock_active,      // From lock_fsm
    input  wire [15:0]  x_in,             // Cleaned X coordinate
    input  wire [15:0]  y_in,             // Cleaned Y coordinate
    input  wire [15:0]  z_in,             // Cleaned Z coordinate
    input  wire         data_in_valid,    // Asserted when x_in/y_in is valid
    output wire         data_in_ready,    // Tracker ready to accept

    output wire [15:0]  x_curr,           // Latest locked target X
    output wire [15:0]  y_curr,           // Latest locked target Y
    output wire [15:0]  z_curr,           // Latest locked target Z
    output wire [15:0]  x_pred,           // Predicted next X
    output wire [15:0]  y_pred,           // Predicted next Y
    output wire [15:0]  z_pred,           // Predicted next Z
    output wire         data_out_valid,   // Output valid flag
    input  wire         data_out_ready,   // Next module ready

    output wire         target_moving     // High if target is moving
);

    // -------------------------------------------------------------------------
    // Threshold to consider movement (used to detect 'target_moving')
    // -------------------------------------------------------------------------
    parameter [15:0] VELOCITY_THRESHOLD = 16'd2;

    // -------------------------------------------------------------------------
    // Internal state
    // -------------------------------------------------------------------------
    reg [15:0] prev_x;
    reg [15:0] prev_y;
    reg [15:0] prev_z;

    reg [15:0] dx;
    reg [15:0] dy;
    reg [15:0] dz;

    reg [15:0] x_reg;
    reg [15:0] y_reg;
    reg [15:0] z_reg;

    reg [15:0] x_predict;
    reg [15:0] y_predict;
    reg [15:0] z_predict;

    reg        buffer_valid;

    // -------------------------------------------------------------------------
    // Velocity estimation (unsigned delta)
    // -------------------------------------------------------------------------
    wire [15:0] delta_x = (x_in > prev_x) ? (x_in - prev_x) : (prev_x - x_in);
    wire [15:0] delta_y = (y_in > prev_y) ? (y_in - prev_y) : (prev_y - y_in);
    wire [15:0] delta_z = (z_in > prev_z) ? (z_in - prev_z) : (prev_z - z_in);

    assign target_moving = (delta_x >= VELOCITY_THRESHOLD) || (delta_y >= VELOCITY_THRESHOLD) || (delta_z >= VELOCITY_THRESHOLD);

    // -------------------------------------------------------------------------
    // Flow control
    // -------------------------------------------------------------------------
    assign data_in_ready  = ~buffer_valid && lock_active;
    assign data_out_valid = buffer_valid;

    // -------------------------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------------------------
    assign x_curr = x_reg;
    assign y_curr = y_reg;
    assign z_curr = z_reg;
    assign x_pred = x_predict;
    assign y_pred = y_predict;
    assign z_pred = z_predict;

    // -------------------------------------------------------------------------
    // Tracking Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            prev_x        <= 16'd0;
            prev_y        <= 16'd0;
            prev_z        <= 16'd0;
            dx            <= 16'd0;
            dy            <= 16'd0;
            dz            <= 16'd0;
            x_reg         <= 16'd0;
            y_reg         <= 16'd0;
            z_reg         <= 16'd0;
            x_predict     <= 16'd0;
            y_predict     <= 16'd0;
            z_predict     <= 16'd0;
            buffer_valid  <= 1'b0;
        end else begin
            if (data_in_valid && data_in_ready) begin
                // Calculate delta
                dx <= x_in - prev_x;
                dy <= y_in - prev_y;
                dy <= z_in - prev_z;

                // Register current values
                x_reg <= x_in;
                y_reg <= y_in;
                z_reg <= z_in;

                // Predict next position assuming linear motion
                x_predict <= x_in + dx;
                y_predict <= y_in + dy;
                z_predict <= z_in + dz;

                // Update previous
                prev_x <= x_in;
                prev_y <= y_in;
                prev_z <= z_in;

                buffer_valid <= 1'b1;
            end else if (buffer_valid && data_out_ready) begin
                buffer_valid <= 1'b0; // Clear buffer when consumed
            end
        end
    end

endmodule
