`timescale 1ns / 1ps

module fibonacci_core_tb;

    parameter CLK_PERIOD = 10;

    reg          clk;
    reg          reset;
    reg          btn_start;
    reg          btn_confirm;
    reg  [15:0]  sw_input;

    wire [3:0]   state_out;
    wire         load_input;
    wire [1:0]   input_sel;
    wire         do_validate;
    wire         do_generate;
    wire [1:0]   gen_step;
    wire [15:0]  input_val_1, input_val_2, input_val_3;
    wire [15:0]  gen_val_1, gen_val_2, gen_val_3, gen_val_4;
    wire         is_valid;
    wire         overflow_flag;

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    control_unit u_ctrl (
        .clk(clk), .reset(reset),
        .btn_start(btn_start), .btn_confirm(btn_confirm),
        .is_valid(is_valid), .overflow(overflow_flag),
        .state_out(state_out), .load_input(load_input),
        .input_sel(input_sel), .do_validate(do_validate),
        .do_generate(do_generate), .gen_step(gen_step)
    );

    datapath u_dp (
        .clk(clk), .reset(reset),
        .sw_input(sw_input), .load_input(load_input),
        .input_sel(input_sel), .do_validate(do_validate),
        .do_generate(do_generate), .gen_step(gen_step),
        .input_val_1(input_val_1), .input_val_2(input_val_2),
        .input_val_3(input_val_3),
        .gen_val_1(gen_val_1), .gen_val_2(gen_val_2),
        .gen_val_3(gen_val_3), .gen_val_4(gen_val_4),
        .is_valid(is_valid), .overflow_flag(overflow_flag)
    );

    task pulse_start;
        begin @(posedge clk); btn_start = 1; @(posedge clk); btn_start = 0; end
    endtask

    task pulse_confirm;
        begin @(posedge clk); btn_confirm = 1; @(posedge clk); btn_confirm = 0; end
    endtask

    task wait_cycles; input integer n; integer i;
        begin for (i = 0; i < n; i = i + 1) @(posedge clk); end
    endtask

    task wait_for_state; input [3:0] target; integer timeout;
        begin
            timeout = 0;
            while (state_out !== target && timeout < 500) begin
                @(posedge clk); timeout = timeout + 1;
            end
        end
    endtask

    integer test_num = 0, pass_count = 0, fail_count = 0;

    task test_sequence;
        input [15:0] v1, v2, v3;
        input expect_valid;
        input [15:0] exp_g1, exp_g2, exp_g3, exp_g4;
        reg test_pass;
        begin
            test_num = test_num + 1;
            test_pass = 1;
            $display("");
            $display("=== TEST %0d: (%0d, %0d, %0d) expect %s ===",
                     test_num, v1, v2, v3, expect_valid ? "VALID" : "INVALID");

            if (state_out != 4'd0) begin
                pulse_start; wait_for_state(4'd0); wait_cycles(3);
            end

            sw_input = v1; wait_cycles(2); pulse_start;
            wait_for_state(4'd2);
            $display("  IN1=%0d", input_val_1);

            sw_input = v2; wait_cycles(2); pulse_confirm;
            wait_for_state(4'd4);
            $display("  IN2=%0d", input_val_2);

            sw_input = v3; wait_cycles(2); pulse_confirm;
            wait_for_state(4'd6);
            $display("  IN3=%0d", input_val_3);

            pulse_confirm; wait_cycles(10);
            $display("  valid=%0b (exp %0b)", is_valid, expect_valid);

            if (is_valid !== expect_valid) test_pass = 0;

            if (expect_valid && is_valid) begin
                wait_for_state(4'd14); wait_cycles(3);
                $display("  G1=%0d(%0d) G2=%0d(%0d) G3=%0d(%0d) G4=%0d(%0d)",
                    gen_val_1, exp_g1, gen_val_2, exp_g2,
                    gen_val_3, exp_g3, gen_val_4, exp_g4);
                if (gen_val_1!==exp_g1 || gen_val_2!==exp_g2 ||
                    gen_val_3!==exp_g3 || gen_val_4!==exp_g4) test_pass = 0;
            end

            if (test_pass) begin
                $display("  PASSED"); pass_count = pass_count + 1;
            end else begin
                $display("  FAILED"); fail_count = fail_count + 1;
            end

            wait_cycles(3); pulse_start;
            wait_for_state(4'd0); wait_cycles(5);
        end
    endtask

    initial begin
        reset = 1; btn_start = 0; btn_confirm = 0; sw_input = 0;
        repeat (10) @(posedge clk); reset = 0; repeat (5) @(posedge clk);

        $display("**** FIBONACCI CORE TESTBENCH ****");

        test_sequence(1, 1, 2, 1, 3, 5, 8, 13);
        test_sequence(3, 5, 8, 1, 13, 21, 34, 55);
        test_sequence(1, 2, 4, 0, 0, 0, 0, 0);
        test_sequence(0, 0, 0, 1, 0, 0, 0, 0);
        test_sequence(0, 1, 1, 1, 2, 3, 5, 8);
        test_sequence(5, 8, 13, 1, 21, 34, 55, 89);
        test_sequence(10, 20, 31, 0, 0, 0, 0, 0);
        test_sequence(100, 155, 255, 1, 410, 665, 1075, 1740);

        $display("");
        $display("**** RESULTS: %0d PASSED, %0d FAILED out of %0d ****",
                 pass_count, fail_count, test_num);
        #200; $finish;
    end

    initial begin #500000; $display("TIMEOUT"); $finish; end

endmodule
