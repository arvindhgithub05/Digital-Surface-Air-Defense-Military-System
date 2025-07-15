`timescale 1ns / 1ps

module coord_parser (
    input  wire         clk,            // System clock
    input  wire         reset_n,        // Active-low synchronous reset

    input  wire [47:0]  data_in,        // 48-bit input: [47:32]=X, [31:16]=Y, [15:0]=Z (Height)
    input  wire         data_in_valid,  // Asserted when input data is valid

    output wire [15:0]  x_coord,        // Output X coordinate (Gray code)
    output wire [15:0]  y_coord,        // Output Y coordinate (Gray code)
    output wire [15:0]  z_coord,        // Output Z (Height) coordinate (Gray code)
    output wire         data_valid,     // Asserted when output data is valid
    input  wire         data_ready      // Asserted when next module is ready
);

    // Internal buffers to store binary coordinates
    reg [15:0] x_buffer_bin;
    reg [15:0] y_buffer_bin;
    reg [15:0] z_buffer_bin;
    reg        buffer_valid;

    // Gray code outputs (assigned from binary)
    wire [15:0] x_gray, y_gray, z_gray;

    assign x_gray = x_buffer_bin ^ (x_buffer_bin >> 1);
    assign y_gray = y_buffer_bin ^ (y_buffer_bin >> 1);
    assign z_gray = z_buffer_bin ^ (z_buffer_bin >> 1);

    // Sequential logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            x_buffer_bin <= 16'd0;
            y_buffer_bin <= 16'd0;
            z_buffer_bin <= 16'd0;
            buffer_valid <= 1'b0;
        end else begin
            if (data_in_valid && !buffer_valid) begin
                x_buffer_bin <= data_in[47:32];
                y_buffer_bin <= data_in[31:16];
                z_buffer_bin <= data_in[15:0];
                buffer_valid <= 1'b1;
            end else if (buffer_valid && data_ready) begin
                buffer_valid <= 1'b0;
            end
        end
    end

    // Output assignments
    assign x_coord    = x_gray;
    assign y_coord    = y_gray;
    assign z_coord    = z_gray;
    assign data_valid = buffer_valid;

endmodule

