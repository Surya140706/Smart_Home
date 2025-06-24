module lighting_tb();
    reg [2:0] luminosity;
    reg motionSensor;
    wire light;

    lighting l (
        .luminosity(luminosity),
        .motionSensor(motionSensor),
        .light(light)
    );

    integer i;
    initial begin
        motionSensor = 1'b1;

        // Motion sensor ON, sweep luminosity
        for (i = 0; i < 8; i = i + 1) begin
            luminosity = i;
            #5;
        end
        for (i = 7; i >= 0; i = i - 1) begin
            luminosity = i;
            #5;
        end

        // Motion sensor OFF, sweep luminosity
        motionSensor = 1'b0;
        for (i = 0; i < 8; i = i + 1) begin
            luminosity = i;
            #5;
        end
        for (i = 7; i >= 0; i = i - 1) begin
            luminosity = i;
            #5;
        end

        #10;
        $finish;  // Ends the simulation
    end

    initial begin
        $dumpfile("lighting_tb.vcd");
        $dumpvars(0, lighting_tb);
    end
endmodule
