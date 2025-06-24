`timescale 1ns/1ps

module smart_home_tb;

  // Inputs
  reg [7:0] smokeDetector, doorState, windowState, humanDetector, motionSensor, lock_button;
  reg [2:0] doorEnable;
  reg [7:0] rs_buttonState, e_buttonState;
  reg [7:0][16:0] in_password, change_password;
  reg [7:0][2:0] luminosity;
  reg [7:0][6:0] temperature;
  reg [16:0] garage_in_password, garage_change_password;
  reg garageState, stove_state, garage_rs_button, garage_e_button, garage_lock_button;
  reg rain_sensor;
  reg [2:0] humidity_level;
  reg [3:0] external_temp;
  reg reset_signal;

  // Outputs
  wire fire_alarm, chimney;
  wire unlock, garageLocked, garage_alarm;
  wire [7:0] light, heater, airConditioner;
  wire [7:0] burglar_alarm_enable;
  wire [7:0][1:0] fan_speed;
  wire [7:0] weather_alert, window_close_cmd, motor_signal;

  // DUT
  smart_home uut (
    .smokeDetector(smokeDetector), .doorState(doorState), .windowState(windowState),
    .humanDetector(humanDetector), .motionSensor(motionSensor), .lock_button(lock_button),
    .doorEnable(doorEnable), .rs_buttonState(rs_buttonState), .e_buttonState(e_buttonState),
    .in_password(in_password), .change_password(change_password),
    .luminosity(luminosity), .temperature(temperature),
    .garage_in_password(garage_in_password), .garage_change_password(garage_change_password),
    .garageState(garageState), .stove_state(stove_state),
    .garage_rs_button(garage_rs_button), .garage_e_button(garage_e_button),
    .garage_lock_button(garage_lock_button), .rain_sensor(rain_sensor),
    .humidity_level(humidity_level), .external_temp(external_temp), .reset_signal(reset_signal),
    .fire_alarm(fire_alarm), .chimney(chimney),
    .unlock(unlock), .garageLocked(garageLocked), .garage_alarm(garage_alarm),
    .light(light), .heater(heater), .airConditioner(airConditioner),
    .burglar_alarm_enable(burglar_alarm_enable), .fan_speed(fan_speed),
    .weather_alert(weather_alert), .window_close_cmd(window_close_cmd), .motor_signal(motor_signal)
  );

  integer i;

  initial begin
    // Initialize
    smokeDetector = 0;
    doorState = 0;
    windowState = 0;
    humanDetector = 0;
    motionSensor = 0;
    lock_button = 0;
    doorEnable = 3'd1;

    rs_buttonState = 8'd0;
    e_buttonState = 8'd0;

    for (i = 0; i < 8; i = i + 1) begin
      in_password[i] = 17'd45675;
      change_password[i] = 17'd99999;
      luminosity[i] = 3'd2;
      temperature[i] = 7'd70;
    end

    garage_in_password = 17'd45675;
    garage_change_password = 17'd99999;
    garageState = 0;
    stove_state = 0;
    garage_rs_button = 0;
    garage_e_button = 0;
    garage_lock_button = 0;
    rain_sensor = 0;
    humidity_level = 3'd0;
    external_temp = 4'd10;
    reset_signal = 0;

    #10;

    // Try to unlock main door with correct password
    e_buttonState[1] = 1;
    #10 e_buttonState[1] = 0;

    // Simulate motion and light trigger
    humanDetector = 8'b00001111;
    motionSensor = 8'b00001111;
    #20;

    // Smoke detected in room 2
    smokeDetector = 8'b00000100;
    #10;

    // Turn on stove
    stove_state = 1;
    #20;
    stove_state = 0;

    // Weather condition: rain
    rain_sensor = 1;
    humidity_level = 3'd6;
    external_temp = 4'd2;
    #20;

    // Lock garage
    garage_lock_button = 1;
    #10 garage_lock_button = 0;

    // Trigger garage unlock
    garage_e_button = 1;
    #10 garage_e_button = 0;

    // Reset system
    reset_signal = 1;
    #10 reset_signal = 0;

    $display("Simulation complete.");
    $finish;
  end
 initial begin
 $dumpfile("smart_home_tb.vcd");
 $dumpvars;
end



endmodule

