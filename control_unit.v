`timescale 1ns / 1ps

module control_unit (
    input  wire        clk,
    input  wire        reset,
    input  wire        btn_start,
    input  wire        btn_confirm,
    input  wire        is_valid,
    input  wire        overflow,

    output reg  [3:0]  state_out,
    output reg         load_input,
    output reg  [1:0]  input_sel,
    output reg         do_validate,
    output reg         do_generate,
    output reg  [1:0]  gen_step
);

    localparam [3:0] S_IDLE       = 4'd0,
                     S_INPUT_1    = 4'd1,
                     S_WAIT_1     = 4'd2,
                     S_INPUT_2    = 4'd3,
                     S_WAIT_2     = 4'd4,
                     S_INPUT_3    = 4'd5,
                     S_WAIT_3     = 4'd6,
                     S_VALIDATE   = 4'd7,
                     S_VALID      = 4'd8,
                     S_INVALID    = 4'd9,
                     S_GENERATE_1 = 4'd10,
                     S_GENERATE_2 = 4'd11,
                     S_GENERATE_3 = 4'd12,
                     S_GENERATE_4 = 4'd13,
                     S_DISPLAY    = 4'd14,
                     S_OVERFLOW   = 4'd15;

    reg [3:0] current_state;
    reg [3:0] next_state;
    reg [3:0] wait_counter;

    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            wait_counter <= 4'd0;
        else if (current_state != next_state)
            wait_counter <= 4'd0;
        else if (wait_counter < 4'd15)
            wait_counter <= wait_counter + 4'd1;
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            S_IDLE:       if (btn_start)   next_state = S_INPUT_1;
            S_INPUT_1:                     next_state = S_WAIT_1;
            S_WAIT_1:     if (btn_confirm) next_state = S_INPUT_2;
            S_INPUT_2:                     next_state = S_WAIT_2;
            S_WAIT_2:     if (btn_confirm) next_state = S_INPUT_3;
            S_INPUT_3:                     next_state = S_WAIT_3;
            S_WAIT_3:     if (btn_confirm) next_state = S_VALIDATE;
            S_VALIDATE: begin
                if (wait_counter >= 4'd1) begin
                    if (is_valid) next_state = S_VALID;
                    else          next_state = S_INVALID;
                end
            end
            S_VALID:      if (wait_counter >= 4'd3) next_state = S_GENERATE_1;
            S_INVALID:    if (btn_start) next_state = S_IDLE;
            S_GENERATE_1: begin
                if (overflow)                  next_state = S_OVERFLOW;
                else if (wait_counter >= 4'd2) next_state = S_GENERATE_2;
            end
            S_GENERATE_2: begin
                if (overflow)                  next_state = S_OVERFLOW;
                else if (wait_counter >= 4'd2) next_state = S_GENERATE_3;
            end
            S_GENERATE_3: begin
                if (overflow)                  next_state = S_OVERFLOW;
                else if (wait_counter >= 4'd2) next_state = S_GENERATE_4;
            end
            S_GENERATE_4: begin
                if (overflow)                  next_state = S_OVERFLOW;
                else if (wait_counter >= 4'd2) next_state = S_DISPLAY;
            end
            S_DISPLAY:    if (btn_start) next_state = S_IDLE;
            S_OVERFLOW:   if (btn_start) next_state = S_IDLE;
            default:      next_state = S_IDLE;
        endcase
    end

    always @(*) begin
        state_out   = current_state;
        load_input  = 1'b0;
        input_sel   = 2'd0;
        do_validate = 1'b0;
        do_generate = 1'b0;
        gen_step    = 2'd0;
        case (current_state)
            S_INPUT_1: begin load_input = 1'b1; input_sel = 2'd0; end
            S_INPUT_2: begin load_input = 1'b1; input_sel = 2'd1; end
            S_INPUT_3: begin load_input = 1'b1; input_sel = 2'd2; end
            S_VALIDATE:begin do_validate = 1'b1; end
            S_GENERATE_1: begin do_generate = 1'b1; gen_step = 2'd0; end
            S_GENERATE_2: begin do_generate = 1'b1; gen_step = 2'd1; end
            S_GENERATE_3: begin do_generate = 1'b1; gen_step = 2'd2; end
            S_GENERATE_4: begin do_generate = 1'b1; gen_step = 2'd3; end
            default: begin end
        endcase
    end

endmodule
