`timescale 1ns / 1ps

module fibonacci_top (
    input  wire       clk,
    input  wire       btn_reset,
    input  wire       btn_start,
    input  wire       btn_confirm,
    input  wire       btn_display,
    input  wire [7:0] sw,
    output wire [7:0] led,
    output wire       uart_txd
);

    reg [2:0] rst_pipe = 3'b111;
    wire reset = rst_pipe[2];

    always @(posedge clk or posedge btn_reset) begin
        if (btn_reset)
            rst_pipe <= 3'b111;
        else
            rst_pipe <= {rst_pipe[1:0], 1'b0};
    end

    wire start_clean, confirm_clean, display_clean;
    wire start_pulse, confirm_pulse, display_pulse;

    debouncer u_deb_start (
        .clk(clk), .reset(reset), .noisy(btn_start), .clean(start_clean)
    );
    debouncer u_deb_confirm (
        .clk(clk), .reset(reset), .noisy(btn_confirm), .clean(confirm_clean)
    );
    debouncer u_deb_display (
        .clk(clk), .reset(reset), .noisy(btn_display), .clean(display_clean)
    );

    edge_detector u_edge_start (
        .clk(clk), .reset(reset), .sig_in(start_clean), .pulse(start_pulse)
    );
    edge_detector u_edge_confirm (
        .clk(clk), .reset(reset), .sig_in(confirm_clean), .pulse(confirm_pulse)
    );
    edge_detector u_edge_display (
        .clk(clk), .reset(reset), .sig_in(display_clean), .pulse(display_pulse)
    );

    wire [7:0] sw_sync;

    switch_sync #(.WIDTH(8)) u_sw_sync (
        .clk(clk), .reset(reset), .sw_in(sw), .sw_out(sw_sync)
    );

    wire [3:0]  state_out;
    wire        load_input;
    wire [1:0]  input_sel;
    wire        do_validate, do_generate;
    wire [1:0]  gen_step;
    wire [15:0] input_val_1, input_val_2, input_val_3;
    wire [15:0] gen_val_1, gen_val_2, gen_val_3, gen_val_4;
    wire        is_valid, overflow_flag;

    control_unit u_ctrl (
        .clk         (clk),
        .reset       (reset),
        .btn_start   (start_pulse),
        .btn_confirm (confirm_pulse),
        .is_valid    (is_valid),
        .overflow    (overflow_flag),
        .state_out   (state_out),
        .load_input  (load_input),
        .input_sel   (input_sel),
        .do_validate (do_validate),
        .do_generate (do_generate),
        .gen_step    (gen_step)
    );

    datapath u_dp (
        .clk           (clk),
        .reset         (reset),
        .sw_input      ({8'd0, sw_sync}),
        .load_input    (load_input),
        .input_sel     (input_sel),
        .do_validate   (do_validate),
        .do_generate   (do_generate),
        .gen_step      (gen_step),
        .input_val_1   (input_val_1),
        .input_val_2   (input_val_2),
        .input_val_3   (input_val_3),
        .gen_val_1     (gen_val_1),
        .gen_val_2     (gen_val_2),
        .gen_val_3     (gen_val_3),
        .gen_val_4     (gen_val_4),
        .is_valid      (is_valid),
        .overflow_flag (overflow_flag)
    );

    wire       tx_start_w, tx_busy_w, tx_done_w;
    wire [7:0] tx_data_w;

    uart_tx #(
        .CLK_FREQ(100_000_000),
        .BAUD(115200)
    ) u_uart (
        .clk      (clk),
        .reset    (reset),
        .tx_start (tx_start_w),
        .tx_data  (tx_data_w),
        .tx_out   (uart_txd),
        .tx_busy  (tx_busy_w),
        .tx_done  (tx_done_w)
    );

    uart_msg u_msg (
        .clk         (clk),
        .reset       (reset),
        .fsm_state   (state_out),
        .input_val_1 (input_val_1),
        .input_val_2 (input_val_2),
        .input_val_3 (input_val_3),
        .gen_val_1   (gen_val_1),
        .gen_val_2   (gen_val_2),
        .gen_val_3   (gen_val_3),
        .gen_val_4   (gen_val_4),
        .tx_done     (tx_done_w),
        .tx_start    (tx_start_w),
        .tx_data     (tx_data_w)
    );

    reg [2:0]  disp_mode;
    reg [24:0] hb_counter;
    wire       heartbeat = hb_counter[24];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            disp_mode  <= 3'd0;
            hb_counter <= 25'd0;
        end
        else begin
            hb_counter <= hb_counter + 25'd1;
            if (display_pulse)
                disp_mode <= disp_mode + 3'd1;
        end
    end

    reg [7:0] led_out;
    always @(*) begin
        case (disp_mode)
            3'd0: led_out = {is_valid, overflow_flag, heartbeat,
                             tx_busy_w, state_out};
            3'd1: led_out = input_val_1[7:0];
            3'd2: led_out = input_val_2[7:0];
            3'd3: led_out = input_val_3[7:0];
            3'd4: led_out = gen_val_1[7:0];
            3'd5: led_out = gen_val_2[7:0];
            3'd6: led_out = gen_val_3[7:0];
            3'd7: led_out = gen_val_4[7:0];
        endcase
    end

    assign led = led_out;

endmodule
