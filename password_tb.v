module password_tb ();
    reg [16:0] in_password, change_password;
    reg rsbuttonState, e_buttonState;

    wire unlock, alarm;

    password_check x (
        .in_password(in_password),
        .change_password(change_password),
        .rs_buttonState(rsbuttonState),
        .e_buttonState(e_buttonState),
        .unlock(unlock),
        .alarm(alarm)
    );

    initial begin
        // Step 1: Reset password using master key
        rsbuttonState = 1'b1;
        in_password = 17'd45675;  // master key
        change_password = 17'd78954;
        e_buttonState = 1'b0;
        #5 e_buttonState = 1'b1;
        #5 e_buttonState = 1'b0;

        // Step 2: Unlock with new password
        rsbuttonState = 1'b0;
        in_password = 17'd78954;
        #5 e_buttonState = 1'b1;
        #5 e_buttonState = 1'b0;

        // Step 3: Wrong password attempts
        in_password = 17'd45;
        repeat (4) begin
            #5 e_buttonState = 1'b1;
            #5 e_buttonState = 1'b0;
        end
        $finish;
    end

    initial begin
        $dumpfile("password_tb.vcd");
        $dumpvars;
    end
endmodule

