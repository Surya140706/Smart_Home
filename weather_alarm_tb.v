module weather_alarm_tb();
    reg [7:0] humanDetector;
    reg [7:0] windowState;
    reg rain_sensor;
    reg [2:0] humidity_level;       // 3-bit
    reg [3:0] external_temp;        // 4-bit

    wire [7:0] weather_alert;
    wire [7:0] window_close_cmd;

    weather_alarm wa (
        .humanDetector(humanDetector),
        .windowState(windowState),
        .rain_sensor(rain_sensor),
        .humidity_level(humidity_level),
        .external_temp(external_temp),
        .weather_alert(weather_alert),
        .window_close_cmd(window_close_cmd)
    );

    initial begin
        // Initial condition: no rain
        humanDetector = 8'b11110000;
        windowState   = 8'b00001111;
        rain_sensor   = 1'b0;
        humidity_level = 3'b011;
        external_temp  = 4'b1001;
        #10;

        // Rain starts
        rain_sensor = 1'b1;
        #10;

        // Some people close windows
        windowState = 8'b00110011;
        #10;

        // More changes
        humanDetector = 8'b10101010;
        windowState   = 8'b11111111;
        humidity_level = 3'b111;
        external_temp  = 4'b0101;
        #10;

        $finish;
    end

    initial begin
        $dumpfile("weather_alarm_tb.vcd");
        $dumpvars;
    end
endmodule
