`timescale 1ns / 1ps

module edge_detector (
    input  wire clk,
    input  wire reset,
    input  wire sig_in,
    output wire pulse
);

    reg sig_d;

    always @(posedge clk or posedge reset) begin
        if (reset)
            sig_d <= 1'b0;
        else
            sig_d <= sig_in;
    end

    assign pulse = sig_in & ~sig_d;

endmodule
