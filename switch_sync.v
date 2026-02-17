`timescale 1ns / 1ps

module switch_sync #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             reset,
    input  wire [WIDTH-1:0] sw_in,
    output reg  [WIDTH-1:0] sw_out
);

    reg [WIDTH-1:0] sync_0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_0 <= {WIDTH{1'b0}};
            sw_out <= {WIDTH{1'b0}};
        end
        else begin
            sync_0 <= sw_in;
            sw_out <= sync_0;
        end
    end

endmodule
