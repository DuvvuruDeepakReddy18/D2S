`timescale 1ns / 1ps

module debouncer #(
    parameter STABLE_CNT = 250000
)(
    input  wire clk,
    input  wire reset,
    input  wire noisy,
    output reg  clean
);

    reg sync_0, sync_1;
    reg [17:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
            count  <= 18'd0;
            clean  <= 1'b0;
        end
        else begin
            sync_0 <= noisy;
            sync_1 <= sync_0;

            if (sync_1 != clean) begin
                if (count == STABLE_CNT - 1) begin
                    clean <= sync_1;
                    count <= 18'd0;
                end
                else begin
                    count <= count + 18'd1;
                end
            end
            else begin
                count <= 18'd0;
            end
        end
    end

endmodule
