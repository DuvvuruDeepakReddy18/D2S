`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD     = 115200
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx_out,
    output wire       tx_busy,
    output reg        tx_done
);

    localparam BAUD_DIV = CLK_FREQ / BAUD;

    reg        active;
    reg [9:0]  shift_reg;
    reg [3:0]  bit_cnt;
    reg [9:0]  tick;

    assign tx_busy = active;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            active    <= 1'b0;
            tx_out    <= 1'b1;
            tx_done   <= 1'b0;
            shift_reg <= 10'h3FF;
            bit_cnt   <= 4'd0;
            tick      <= 10'd0;
        end
        else begin
            tx_done <= 1'b0;
            if (!active) begin
                tx_out <= 1'b1;
                if (tx_start) begin
                    shift_reg <= {1'b1, tx_data, 1'b0};
                    active    <= 1'b1;
                    bit_cnt   <= 4'd0;
                    tick      <= 10'd0;
                end
            end
            else begin
                tx_out <= shift_reg[0];
                if (tick < BAUD_DIV - 1)
                    tick <= tick + 10'd1;
                else begin
                    tick <= 10'd0;
                    if (bit_cnt < 4'd9) begin
                        shift_reg <= {1'b1, shift_reg[9:1]};
                        bit_cnt   <= bit_cnt + 4'd1;
                    end
                    else begin
                        active  <= 1'b0;
                        tx_done <= 1'b1;
                    end
                end
            end
        end
    end

endmodule
