`timescale 1ps/1ps

module fire_ctrl (
    input  wire         clk,
    input  wire         reset_n,

    input  wire         lock_active,      // From lock_fsm
    input  wire         target_moving,    // From tracker_core

    input  wire [15:0]  x_curr,           // Current X
    input  wire [15:0]  y_curr,           // Current Y
    input  wire [15:0]  z_curr,           // Current Z
    input  wire [15:0]  x_pred,           // Predicted X
    input  wire [15:0]  y_pred,           // Predicted Y
    input  wire [15:0]  z_pred,           // Predicted Z

    output reg          fire_pulse        // Single-cycle fire signal
);

    // -------------------------------------------------------------------------
    // Fire window threshold (tune for your system)
    // -------------------------------------------------------------------------
    parameter [15:0] STRIKE_TOLERANCE = 16'd3;

    // -------------------------------------------------------------------------
    // Internal logic to compute absolute deltas
    // -------------------------------------------------------------------------
    wire [15:0] dx = (x_curr > x_pred) ? (x_curr - x_pred) : (x_pred - x_curr);
    wire [15:0] dy = (y_curr > y_pred) ? (y_curr - y_pred) : (y_pred - y_curr);
    wire [15:0] dz = (z_curr > z_pred) ? (z_curr - z_pred) : (z_pred - z_curr);

    wire within_strike_window = (dx <= STRIKE_TOLERANCE) && (dy <= STRIKE_TOLERANCE) && (dz <= STRIKE_TOLERANCE);

    // -------------------------------------------------------------------------
    // Fire pulse logic — asserted for exactly one clock cycle
    // -------------------------------------------------------------------------
    reg fire_armed;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            fire_pulse <= 1'b0;
            fire_armed <= 1'b0;
        end else begin
            if (lock_active && within_strike_window && target_moving && ~fire_armed) begin
                fire_pulse <= 1'b1;    // Pulse high
                fire_armed <= 1'b1;    // Arm once to avoid repeated fire
            end else begin
                fire_pulse <= 1'b0;    // Keep pulse 1-cycle wide

                // Re-arm when target is no longer within strike zone
                if (!within_strike_window)
                    fire_armed <= 1'b0;
            end
        end
    end

endmodule
