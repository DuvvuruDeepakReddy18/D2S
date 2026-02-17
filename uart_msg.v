`timescale 1ns / 1ps

module uart_msg (
    input  wire        clk,
    input  wire        reset,
    input  wire [3:0]  fsm_state,
    input  wire [15:0] input_val_1,
    input  wire [15:0] input_val_2,
    input  wire [15:0] input_val_3,
    input  wire [15:0] gen_val_1,
    input  wire [15:0] gen_val_2,
    input  wire [15:0] gen_val_3,
    input  wire [15:0] gen_val_4,
    input  wire        tx_done,
    output wire        tx_start,
    output wire [7:0]  tx_data
);

    localparam S_IDLE = 4'd0, S_WAIT_1 = 4'd2, S_WAIT_2 = 4'd4,
               S_WAIT_3 = 4'd6, S_VALID = 4'd8, S_INVALID = 4'd9,
               S_DISPLAY = 4'd14, S_OVERFLOW = 4'd15;

    localparam MT_NONE = 4'd0, MT_READY = 4'd1, MT_IN1 = 4'd2,
               MT_IN2 = 4'd3, MT_IN3 = 4'd4, MT_VALID = 4'd5,
               MT_INVAL = 4'd6, MT_RESULT = 4'd7, MT_OFLOW = 4'd8;

    localparam MS_IDLE = 2'd0, MS_SEND = 2'd1,
               MS_WAIT = 2'd2, MS_ADV  = 2'd3;

    reg [1:0] ms_state;
    reg [3:0] msg_type;
    reg [4:0] byte_idx;
    reg [3:0] prev_fsm;

    function [7:0] hex_ascii;
        input [3:0] nib;
        begin
            case (nib)
                4'h0: hex_ascii = 8'h30; 4'h1: hex_ascii = 8'h31;
                4'h2: hex_ascii = 8'h32; 4'h3: hex_ascii = 8'h33;
                4'h4: hex_ascii = 8'h34; 4'h5: hex_ascii = 8'h35;
                4'h6: hex_ascii = 8'h36; 4'h7: hex_ascii = 8'h37;
                4'h8: hex_ascii = 8'h38; 4'h9: hex_ascii = 8'h39;
                4'hA: hex_ascii = 8'h41; 4'hB: hex_ascii = 8'h42;
                4'hC: hex_ascii = 8'h43; 4'hD: hex_ascii = 8'h44;
                4'hE: hex_ascii = 8'h45; 4'hF: hex_ascii = 8'h46;
                default: hex_ascii = 8'h3F;
            endcase
        end
    endfunction

    reg [4:0] msg_len;
    always @(*) begin
        case (msg_type)
            MT_READY:  msg_len = 5'd13;
            MT_IN1:    msg_len = 5'd9;
            MT_IN2:    msg_len = 5'd9;
            MT_IN3:    msg_len = 5'd9;
            MT_VALID:  msg_len = 5'd8;
            MT_INVAL:  msg_len = 5'd10;
            MT_RESULT: msg_len = 5'd23;
            MT_OFLOW:  msg_len = 5'd11;
            default:   msg_len = 5'd0;
        endcase
    end

    reg [7:0] msg_byte;
    always @(*) begin
        msg_byte = 8'h00;
        case (msg_type)
            MT_READY: begin
                case (byte_idx)
                    5'd0:  msg_byte = 8'h0D; 5'd1:  msg_byte = 8'h0A;
                    5'd2:  msg_byte = "=";    5'd3:  msg_byte = "=";
                    5'd4:  msg_byte = "R";    5'd5:  msg_byte = "E";
                    5'd6:  msg_byte = "A";    5'd7:  msg_byte = "D";
                    5'd8:  msg_byte = "Y";    5'd9:  msg_byte = "=";
                    5'd10: msg_byte = "=";
                    5'd11: msg_byte = 8'h0D;  5'd12: msg_byte = 8'h0A;
                    default: msg_byte = 8'h00;
                endcase
            end
            MT_IN1: begin
                case (byte_idx)
                    5'd0: msg_byte = "I";     5'd1: msg_byte = "1";
                    5'd2: msg_byte = ":";
                    5'd3: msg_byte = hex_ascii(input_val_1[15:12]);
                    5'd4: msg_byte = hex_ascii(input_val_1[11:8]);
                    5'd5: msg_byte = hex_ascii(input_val_1[7:4]);
                    5'd6: msg_byte = hex_ascii(input_val_1[3:0]);
                    5'd7: msg_byte = 8'h0D;   5'd8: msg_byte = 8'h0A;
                    default: msg_byte = 8'h00;
                endcase
            end
            MT_IN2: begin
                case (byte_idx)
                    5'd0: msg_byte = "I";     5'd1: msg_byte = "2";
                    5'd2: msg_byte = ":";
                    5'd3: msg_byte = hex_ascii(input_val_2[15:12]);
                    5'd4: msg_byte = hex_ascii(input_val_2[11:8]);
                    5'd5: msg_byte = hex_ascii(input_val_2[7:4]);
                    5'd6: msg_byte = hex_ascii(input_val_2[3:0]);
                    5'd7: msg_byte = 8'h0D;   5'd8: msg_byte = 8'h0A;
                    default: msg_byte = 8'h00;
                endcase
            end
            MT_IN3: begin
                case (byte_idx)
                    5'd0: msg_byte = "I";     5'd1: msg_byte = "3";
                    5'd2: msg_byte = ":";
                    5'd3: msg_byte = hex_ascii(input_val_3[15:12]);
                    5'd4: msg_byte = hex_ascii(input_val_3[11:8]);
                    5'd5: msg_byte = hex_ascii(input_val_3[7:4]);
                    5'd6: msg_byte = hex_ascii(input_val_3[3:0]);
                    5'd7: msg_byte = 8'h0D;   5'd8: msg_byte = 8'h0A;
                    default: msg_byte = 8'h00;
                endcase
            end
            MT_VALID: begin
                case (byte_idx)
                    5'd0: msg_byte = "V"; 5'd1: msg_byte = "A";
                    5'd2: msg_byte = "L"; 5'd3: msg_byte = "I";
                    5'd4: msg_byte = "D"; 5'd5: msg_byte = "!";
                    5'd6: msg_byte = 8'h0D; 5'd7: msg_byte = 8'h0A;
                    default: msg_byte = 8'h00;
                endcase
            end
            MT_INVAL: begin
                case (byte_idx)
                    5'd0: msg_byte = "I"; 5'd1: msg_byte = "N";
                    5'd2: msg_byte = "V"; 5'd3: msg_byte = "A";
                    5'd4: msg_byte = "L"; 5'd5: msg_byte = "I";
                    5'd6: msg_byte = "D"; 5'd7: msg_byte = "!";
                    5'd8: msg_byte = 8'h0D; 5'd9: msg_byte = 8'h0A;
                    default: msg_byte = 8'h00;
                endcase
            end
            MT_RESULT: begin
                case (byte_idx)
                    5'd0:  msg_byte = "G";
                    5'd1:  msg_byte = ":";
                    5'd2:  msg_byte = hex_ascii(gen_val_1[15:12]);
                    5'd3:  msg_byte = hex_ascii(gen_val_1[11:8]);
                    5'd4:  msg_byte = hex_ascii(gen_val_1[7:4]);
                    5'd5:  msg_byte = hex_ascii(gen_val_1[3:0]);
                    5'd6:  msg_byte = ",";
                    5'd7:  msg_byte = hex_ascii(gen_val_2[15:12]);
                    5'd8:  msg_byte = hex_ascii(gen_val_2[11:8]);
                    5'd9:  msg_byte = hex_ascii(gen_val_2[7:4]);
                    5'd10: msg_byte = hex_ascii(gen_val_2[3:0]);
                    5'd11: msg_byte = ",";
                    5'd12: msg_byte = hex_ascii(gen_val_3[15:12]);
                    5'd13: msg_byte = hex_ascii(gen_val_3[11:8]);
                    5'd14: msg_byte = hex_ascii(gen_val_3[7:4]);
                    5'd15: msg_byte = hex_ascii(gen_val_3[3:0]);
                    5'd16: msg_byte = ",";
                    5'd17: msg_byte = hex_ascii(gen_val_4[15:12]);
                    5'd18: msg_byte = hex_ascii(gen_val_4[11:8]);
                    5'd19: msg_byte = hex_ascii(gen_val_4[7:4]);
                    5'd20: msg_byte = hex_ascii(gen_val_4[3:0]);
                    5'd21: msg_byte = 8'h0D;
                    5'd22: msg_byte = 8'h0A;
                    default: msg_byte = 8'h00;
                endcase
            end
            MT_OFLOW: begin
                case (byte_idx)
                    5'd0:  msg_byte = "O";  5'd1:  msg_byte = "V";
                    5'd2:  msg_byte = "E";  5'd3:  msg_byte = "R";
                    5'd4:  msg_byte = "F";  5'd5:  msg_byte = "L";
                    5'd6:  msg_byte = "O";  5'd7:  msg_byte = "W";
                    5'd8:  msg_byte = "!";
                    5'd9:  msg_byte = 8'h0D; 5'd10: msg_byte = 8'h0A;
                    default: msg_byte = 8'h00;
                endcase
            end
            default: msg_byte = 8'h00;
        endcase
    end

    reg [3:0] next_msg;
    always @(*) begin
        case (fsm_state)
            S_IDLE:     next_msg = MT_READY;
            S_WAIT_1:   next_msg = MT_IN1;
            S_WAIT_2:   next_msg = MT_IN2;
            S_WAIT_3:   next_msg = MT_IN3;
            S_VALID:    next_msg = MT_VALID;
            S_INVALID:  next_msg = MT_INVAL;
            S_DISPLAY:  next_msg = MT_RESULT;
            S_OVERFLOW: next_msg = MT_OFLOW;
            default:    next_msg = MT_NONE;
        endcase
    end

    wire fsm_changed = (fsm_state != prev_fsm);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ms_state <= MS_IDLE;
            msg_type <= MT_NONE;
            byte_idx <= 5'd0;
            prev_fsm <= 4'hF;
        end
        else begin
            case (ms_state)
                MS_IDLE: begin
                    prev_fsm <= fsm_state;
                    if (fsm_changed && next_msg != MT_NONE) begin
                        msg_type <= next_msg;
                        byte_idx <= 5'd0;
                        ms_state <= MS_SEND;
                    end
                end
                MS_SEND: ms_state <= MS_WAIT;
                MS_WAIT: if (tx_done) ms_state <= MS_ADV;
                MS_ADV: begin
                    if (msg_len == 5'd0 || byte_idx == msg_len - 5'd1)
                        ms_state <= MS_IDLE;
                    else begin
                        byte_idx <= byte_idx + 5'd1;
                        ms_state <= MS_SEND;
                    end
                end
                default: ms_state <= MS_IDLE;
            endcase
        end
    end

    assign tx_start = (ms_state == MS_SEND);
    assign tx_data  = msg_byte;

endmodule
