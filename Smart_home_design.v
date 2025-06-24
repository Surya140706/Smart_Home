`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:  Vaddadi Sri Surya Gunwanth
// Design Name:  This is the central control module that manages all sensor inputs and controls home automation systems like lighting, temperature, security, and alarms.
// Module Name: smart_home
// Project Name:  HomeSense 8 – A smart automation system for secure and adaptive control of an 8-room home.
//////////////////////////////////////////////////////////////////////////////////


module mux_8_16b(sel, inp, out);
  input [2:0] sel;
  input [7:0][16:0] inp;
  output [16:0] out;
  assign out = inp[sel];
endmodule

module mux_8(sel, inp, out);
  input [2:0] sel;
  input [7:0] inp;
  output out;
  assign out = inp[sel];
endmodule

// Smart Home System for 8-room automation
module smart_home(
  // 8-bit inputs for each room
  input [7:0] smokeDetector, doorState, windowState, humanDetector, motionSensor, lock_button,
  input [2:0] doorEnable, // selects which door's password is active
  input [7:0] rs_buttonState, e_buttonState, // reset and enter buttons for each room
  input [7:0][16:0] in_password, change_password, // current and new passwords
  input [7:0][2:0] luminosity, // light level in 3-bit for each room
  input [7:0][6:0] temperature, // 7-bit Fahrenheit temperature for each room
  input [16:0] garage_in_password, garage_change_password, // garage password inputs
  input garageState, stove_state, garage_rs_button, garage_e_button, garage_lock_button, // garage and kitchen controls
  input rain_sensor,
  input [2:0] humidity_level,
  input [3:0] external_temp,
  input reset_signal,

  // Outputs
  output fire_alarm, chimney,
  output reg unlock, garageLocked, garage_alarm,
  output [7:0] light, heater, airConditioner,
  output reg [7:0] burglar_alarm_enable,
  output [7:0][1:0] fan_speed,
  output [7:0] weather_alert, window_close_cmd, motor_signal
);

  // Internal wires for burglar alarm module
  wire [7:0] burglar_alarm_s;
  wire garage_alarm_sb;

  // Burglar alarm instance
  burglar_alarm b (
    .doorState(doorState), .windowState(windowState), .garageState(garageState),
    .homeLocked(!unlock), .garageLocked(garageLocked), .reset(reset_signal),
    .alarmEnable(burglar_alarm_s), .garageAlarm(garage_alarm_sb)
  );

  // Enables room burglar alarms
  always @(posedge reset_signal or burglar_alarm_s) begin
    if (reset_signal)
      burglar_alarm_enable <= 8'd0;
    else begin
      for (integer i = 0; i < 8; i = i + 1) begin
        if (burglar_alarm_s[i])
          burglar_alarm_enable[i] = 1'b1;
      end
    end
  end

  // Garage-specific alarm logic
  always @(posedge garage_alarm_sb or posedge reset_signal) begin
    if (reset_signal)
      garage_alarm <= 1'b0;
    else
      garage_alarm <= 1'b1;
  end

  // Kitchen automation module (chimney control)
  kitchen k (.stove_state(stove_state), .chimney(chimney));

  // Device control (AC and lights) for all rooms
  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1) begin: devices
      airConditioning ac1 (
        .temperature(temperature[i]), .heater(heater[i]), .airConditioner(airConditioner[i]),
        .humanDetector(humanDetector[i]), .fan_speed(fan_speed[i])
      );
      lighting l (
        .luminosity(luminosity[i]), .motionSensor(motionSensor[i]), .light(light[i])
      );
    end
  endgenerate

  // Multiplexers for selecting password, change password, and button states
  wire [16:0] password_in, password_change;
  wire buttonState_e, buttonState_rs;

  mux_8_16b m1 (doorEnable, in_password, password_in);
  mux_8_16b m2 (doorEnable, change_password, password_change);
  mux_8 m3 (doorEnable, rs_buttonState, buttonState_rs);  
  mux_8 m4 (doorEnable, e_buttonState, buttonState_e);    

  // Main door password system
  wire unlock_s, alarm_s;
  password_check p (
    .in_password(password_in), .change_password(password_change),
    .rs_buttonState(buttonState_rs), .e_buttonState(buttonState_e),
    .unlock(unlock_s), .alarm(alarm_s)
  );

  // System initialization
  initial begin
    burglar_alarm_enable <= 8'd0;
    unlock <= 1'b0;
    garageLocked <= 1'b0;
    garage_alarm <= 1'b0;
  end

  // Main door unlock or alarm trigger
  always @(posedge unlock_s or posedge alarm_s) begin
    if (unlock_s)
      unlock <= 1'b1;
    if (alarm_s)
      burglar_alarm_enable[doorEnable] <= 1'b1;
  end

  // Lock button handler (deactivates unlock)
  always @(lock_button) begin
    if (lock_button > 0)
      unlock = 1'b0;
  end

  // Fire alarm module
  fire_alarm f (.smoke_detector(smokeDetector), .alarmEnable(fire_alarm));

  // Garage password system
  wire garage_unlock_s;
  wire garage_alarm_s;
  password_check pg (
    .in_password(garage_in_password), .change_password(garage_change_password),
    .rs_buttonState(garage_rs_button), .e_buttonState(garage_e_button),
    .unlock(garage_unlock_s), .alarm(garage_alarm_s)
  );

  // Garage door control logic
  always @(posedge garage_unlock_s or posedge garage_alarm_s or posedge reset_signal) begin
    if (reset_signal)
      garage_alarm <= 1'b0;
    else if (garage_unlock_s)
      garageLocked <= 1'b0;
    else if (garage_alarm_s)
      garage_alarm <= 1'b1;
  end

  // Manually lock the garage
  always @(posedge garage_lock_button) begin
    garageLocked = 1'b1;
  end

  // Weather monitoring and automated window control
  weather_alarm wa1 (
    .humanDetector(humanDetector), .windowState(windowState), .rain_sensor(rain_sensor),
    .humidity_level(humidity_level), .external_temp(external_temp),
    .weather_alert(weather_alert), .window_close_cmd(window_close_cmd)
  );

  // Window motor controller
  window_control wc1 (
    .window_close_cmd(window_close_cmd), .windowState(windowState), .motor_signal(motor_signal)
  );
endmodule

// Air Conditioning Control Module
// Controls heater, air conditioner, and fan speed based on temperature and presence (humanDetector)
module airConditioning(
  input [6:0] temperature,           // 7-bit input temperature in Fahrenheit (0–127)
  input humanDetector,              // Active when someone is present in the room
  output reg heater,                // Heater ON/OFF control
  output reg airConditioner,        // Air conditioner ON/OFF control
  output reg [1:0] fan_speed        // 2-bit fan speed: 00 = OFF, 01 = Low, 10 = Medium, 11 = High
);

  // Always evaluate when inputs change
  always @(*) begin
    if (humanDetector) begin 
      // If temperature is less than 60°F, turn on the heater
      if (temperature < 7'd60) begin
        heater = 1'b1;
        airConditioner = 1'b0;
        fan_speed = 2'd0;
      end
      // Temperature between 60°F and 72°F: comfortable, everything OFF
      else if (temperature >= 7'd60 && temperature <= 7'd72) begin
        heater = 1'b0;
        airConditioner = 1'b0;
        fan_speed = 2'd0;
      end
      // Temperature between 73°F and 78°F: use medium fan
      else if (temperature >= 7'd73 && temperature <= 7'd78) begin
        heater = 1'b0;
        airConditioner = 1'b0;
        fan_speed = 2'd2;
      end
      // Temperature between 79°F and 84°F: use high fan
      else if (temperature >= 7'd79 && temperature <= 7'd84) begin
        heater = 1'b0;
        airConditioner = 1'b0;
        fan_speed = 2'd3;
      end
      // Temperature above 84°F: turn on AC and set fan to low
      else begin
        heater = 1'b0;
        airConditioner = 1'b1;
        fan_speed = 2'd1;
      end
    end
    else begin
      // No one present — turn everything off
      heater = 1'b0;
      airConditioner = 1'b0;
      fan_speed = 2'd0;
    end
  end
endmodule


module kitchen(stove_state, chimney);
  input stove_state;          // Input signal indicating the state of the stove (1 = ON, 0 = OFF)
  output reg chimney;         // Output signal to control the chimney (1 = ON, 0 = OFF)

  always @(stove_state) begin // Trigger block whenever stove_state changes
    if (stove_state)
      chimney = 1'b1;         // If stove is ON, chimney remains ON
    else begin
      chimney = 1'b1;         // If stove is OFF, chimney remains ON temporarily
      chimney = #60 1'b0;     // After 60 time units, turn chimney OFF (simulate delay for ventilation)
    end
  end
endmodule

module lighting (luminosity, motionSensor, light) ;
  input [2:0] luminosity ;         // 3-bit input representing ambient light level (0 to 7)
  input motionSensor ;             // Input from motion sensor (1 = motion detected, 0 = no motion)
  output reg light ;               // Output to control the light (1 = ON, 0 = OFF)

  always @(*) begin                // Combinational logic block
    if(luminosity < 3'd4 & motionSensor) // If light level is low AND motion is detected
      light = 1'b1;                // Turn the light ON
    else
      light = 1'b0;                // Otherwise, turn the light OFF
  end
endmodule


// Fire Alarm Module
// Triggers a central alarm if any room's smoke detector is activated

module fire_alarm(
  input [7:0] smoke_detector,    // Each bit represents one room's smoke detector (8 rooms)
  output reg alarmEnable         // Fire alarm output signal (1 if smoke is detected anywhere)
);

  // Combinational logic block that triggers alarm when any smoke is detected
  always @(*) begin
    if (smoke_detector != 8'd0)
      alarmEnable <= 1'b1;        // Alarm ON if any smoke detector is active
    else
      alarmEnable <= 1'b0;        // Alarm OFF if no smoke detected in any room
  end

endmodule


// Weather Alarm Module
// Monitors outdoor conditions and human presence to generate alerts and window control commands

module weather_alarm(
    input [7:0] humanDetector,         // Human presence in each room (8 rooms)
    input [7:0] windowState,           // Not used in logic, but represents current window status per room
    input rain_sensor,                 // Single-bit rain sensor input
    input [2:0] humidity_level,        // 3-bit humidity level (0–7)
    input [3:0] external_temp,         // 4-bit external temperature (0–15)
    output reg [7:0] weather_alert,    // Weather alert signal for each room
    output reg [7:0] window_close_cmd  // Window close command for each room
);

    integer i;

    // Combinational logic block to set alerts and window close commands
    always @(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            // If someone is in the room AND it’s raining OR too humid OR too cold
            if (humanDetector[i] && (rain_sensor || humidity_level > 3'd5 || external_temp < 4'd4)) begin
                weather_alert[i] = 1;         // Activate weather alert for that room
                window_close_cmd[i] = 1;      // Issue window close command
            end else begin
                weather_alert[i] = 0;         // No alert
                window_close_cmd[i] = 0;      // No command
            end
        end
    end
endmodule

module window_control(
    input [7:0] window_close_cmd,   // 8-bit command signal indicating which windows should be closed (1 = close)
    input [7:0] windowState,        // 8-bit input showing the current state of each window (1 = open, 0 = closed)
    output reg [7:0] motor_signal   // 8-bit output to control the window motors (1 = activate motor to close window)
);
    always @(*) begin
        // Activate motor only for windows that are commanded to close AND are currently open
        motor_signal = window_close_cmd & windowState;
    end
endmodule


module password_check(
  input [16:0] in_password, change_password,  // Input password to check and new password to change
  input rs_buttonState, e_buttonState,        // rs_buttonState: 0 = unlock request, 1 = change password request
  output reg unlock, alarm                    // Outputs: unlock signal and alarm signal
);

  reg [16:0] unique_key;                      // A special key that can always unlock
  reg [16:0] password;                        // Current password
  reg [2:0] count;                            // Counter for wrong attempts (max 3)

  initial begin
    unlock = 1'b0;                            // Initially, system is locked
    alarm = 1'b0;                             // No alarm initially
    password = 17'd45675;                     // Default password
    unique_key = 17'd45675;                   // Default unique override key
    count = 3'd0;                             // Wrong attempt counter set to 0
  end

  always @(posedge e_buttonState) begin       // Triggered on Enter button press
    if (in_password == password || in_password == unique_key) begin
      count <= 3'd0;                          // Reset counter on correct password
      if (rs_buttonState == 1'b0) begin
        unlock <= 1'b1;                       // Unlock if user pressed unlock (not change password)
      end
      else if (rs_buttonState == 1'b1) begin
        password <= change_password;          // Change password if user pressed change button
      end
    end
    else begin
      count <= count + 1;                     // Increment counter on wrong password
    end

    if (count >= 3) begin
      alarm <= 1'b1;                          // Trigger alarm after 3 wrong attempts
    end
  end

  // Optional block to clear unlock and alarm flags after one cycle
  always @(posedge unlock or posedge alarm) begin
    if (unlock)
      unlock <= 1'b0;                         // Clear unlock signal
    if (alarm)
      alarm <= 1'b0;                          // Clear alarm signal
  end

endmodule

// Burglar Alarm Module
// Monitors door/window states and garage to trigger security alarms

module burglar_alarm(
  input [7:0] doorState, windowState,     // Door and window states for 8 rooms
  input garageState,                      // Garage open/close status
  input homeLocked, garageLocked,         // Lock status of home and garage
  input reset,                            // Reset signal to clear alarms
  output reg [7:0] alarmEnable,           // Alarm signal per room
  output reg garageAlarm                  // Alarm signal for garage
);
  integer i;

  // Room-wise burglar alarm logic
  always @(*) begin
    if (reset) begin
      alarmEnable = 8'd0;                 // Clear all room alarms on reset
    end
    else begin
      // If door or window is open while home is locked, trigger room alarm
      for (i = 0; i < 8; i = i + 1) begin
        alarmEnable[i] = (doorState[i] | windowState[i]) & homeLocked;
      end
    end
  end

  // Garage alarm logic triggered on rising edge of lock/open signals or reset
  always @(posedge garageLocked or posedge garageState or posedge reset) begin
    if (reset)
      garageAlarm <= 1'b0;                // Reset garage alarm
    else if (garageLocked & garageState)
      garageAlarm <= 1'b1;                // Garage is locked but opened — trigger alarm
  end

endmodule
