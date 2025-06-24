module window_control_tb();
    reg [7:0] window_close_cmd;
    reg [7:0] windowState;
    wire [7:0] motor_signal;

    window_control wc (
        .window_close_cmd(window_close_cmd),
        .windowState(windowState),
        .motor_signal(motor_signal)
    );

    initial begin
        // Test 1: All windows closed, command sent
        window_close_cmd = 8'b11111111;
        windowState = 8'b00000000;
        #5;

        // Test 2: All windows open, command sent
        windowState = 8'b11111111;
        #5;

        // Test 3: Alternate windows open, command sent
        windowState = 8'b10101010;
        #5;

        // Test 4: Alternate commands
        window_close_cmd = 8'b01010101;
        #5;

        // Test 5: No command
        window_close_cmd = 8'b00000000;
        #5;

        $finish;
    end

    initial begin
        $dumpfile("window_control_tb.vcd");
        $dumpvars;
    end
endmodule
