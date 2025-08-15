`timescale 1ps/1ps

module lock_fsm (
    input  wire clk,               // System clock
    input  wire reset_n,           // Active-low synchronous reset

    input  wire target_found,      // From target_acq.v
    input  wire data_valid,        // Fresh coordinate available
    output reg  lock_active        // HIGH = target is locked
);

    // -------------------------------------------------------------------------
    // FSM State Definitions
    // -------------------------------------------------------------------------
    typedef enum reg [2:0] {
        STATE_IDLE    = 3'd0,
        STATE_ACQUIRE = 3'd1,
        STATE_VERIFY  = 3'd2,
        STATE_LOCKED  = 3'd3,
        STATE_LOST    = 3'd4
    } state_t;

    state_t state, next_state;

    // -------------------------------------------------------------------------
    // Timeout Counter: For detecting signal loss in LOCKED state
    // -------------------------------------------------------------------------
    parameter TIMEOUT_MAX = 16'd50000;  // Tune based on clk freq (e.g., ~1ms)
    reg [15:0] timeout_counter;

    // -------------------------------------------------------------------------
    // FSM State Register
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= STATE_IDLE;
        else
            state <= next_state;
    end

    // -------------------------------------------------------------------------
    // FSM Next State Logic
    // -------------------------------------------------------------------------
    always @(*) begin
        // Default to current state
        next_state = state;

        case (state)
            STATE_IDLE: begin
                if (target_found)
                    next_state = STATE_ACQUIRE;
            end

            STATE_ACQUIRE: begin
                if (target_found)
                    next_state = STATE_VERIFY;
                else
                    next_state = STATE_IDLE;
            end

            STATE_VERIFY: begin
                if (target_found)
                    next_state = STATE_LOCKED;
                else
                    next_state = STATE_IDLE;
            end

            STATE_LOCKED: begin
                if (timeout_counter >= TIMEOUT_MAX)
                    next_state = STATE_LOST;
            end

            STATE_LOST: begin
                next_state = STATE_IDLE;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

    // -------------------------------------------------------------------------
    // Timeout Counter Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            timeout_counter <= 16'd0;
        else if (state == STATE_LOCKED) begin
            if (data_valid)
                timeout_counter <= 16'd0; // Reset on new data
            else
                timeout_counter <= timeout_counter + 1'b1;
        end else
            timeout_counter <= 16'd0;
    end

    // -------------------------------------------------------------------------
    // Output: Lock Signal Control
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            lock_active <= 1'b0;
        else begin
            if (state == STATE_LOCKED)
                lock_active <= 1'b1;
            else
                lock_active <= 1'b0;
        end
    end

endmodule
