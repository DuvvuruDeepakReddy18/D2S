`timescale 1ns / 1ps

module datapath (
    input  wire        clk,
    input  wire        reset,
    input  wire [15:0] sw_input,
    input  wire        load_input,
    input  wire [1:0]  input_sel,
    input  wire        do_validate,
    input  wire        do_generate,
    input  wire [1:0]  gen_step,

    output reg  [15:0] input_val_1,
    output reg  [15:0] input_val_2,
    output reg  [15:0] input_val_3,
    output reg  [15:0] gen_val_1,
    output reg  [15:0] gen_val_2,
    output reg  [15:0] gen_val_3,
    output reg  [15:0] gen_val_4,
    output reg         is_valid,
    output reg         overflow_flag
);

    wire [16:0] sum_validate;
    assign sum_validate = {1'b0, input_val_1} + {1'b0, input_val_2};

    reg  [15:0] adder_a;
    reg  [15:0] adder_b;
    wire [16:0] adder_result;
    assign adder_result = {1'b0, adder_a} + {1'b0, adder_b};

    always @(*) begin
        case (gen_step)
            2'd0: begin adder_a = input_val_2; adder_b = input_val_3; end
            2'd1: begin adder_a = input_val_3; adder_b = gen_val_1;   end
            2'd2: begin adder_a = gen_val_1;   adder_b = gen_val_2;   end
            2'd3: begin adder_a = gen_val_2;   adder_b = gen_val_3;   end
            default: begin adder_a = 16'd0;    adder_b = 16'd0;       end
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            input_val_1 <= 16'd0;
            input_val_2 <= 16'd0;
            input_val_3 <= 16'd0;
        end
        else if (load_input) begin
            case (input_sel)
                2'd0: input_val_1 <= sw_input;
                2'd1: input_val_2 <= sw_input;
                2'd2: input_val_3 <= sw_input;
                default: ;
            endcase
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            is_valid <= 1'b0;
        else if (do_validate)
            is_valid <= (sum_validate[15:0] == input_val_3) && (~sum_validate[16]);
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            gen_val_1     <= 16'd0;
            gen_val_2     <= 16'd0;
            gen_val_3     <= 16'd0;
            gen_val_4     <= 16'd0;
            overflow_flag <= 1'b0;
        end
        else if (do_generate) begin
            if (adder_result[16])
                overflow_flag <= 1'b1;
            else begin
                case (gen_step)
                    2'd0: gen_val_1 <= adder_result[15:0];
                    2'd1: gen_val_2 <= adder_result[15:0];
                    2'd2: gen_val_3 <= adder_result[15:0];
                    2'd3: gen_val_4 <= adder_result[15:0];
                    default: ;
                endcase
            end
        end
        else if (do_validate) begin
            gen_val_1     <= 16'd0;
            gen_val_2     <= 16'd0;
            gen_val_3     <= 16'd0;
            gen_val_4     <= 16'd0;
            overflow_flag <= 1'b0;
        end
    end

endmodule
