module burglar_alarm_tb;

  reg [7:0] doorState, windowState;
  reg garageState;
  reg homeLocked, garageLocked;
  reg reset;
  wire [7:0] alarmEnable;
  wire garageAlarm;

  // Instantiate the module under test
  burglar_alarm uut (
    .doorState(doorState),
    .windowState(windowState),
    .garageState(garageState),
    .homeLocked(homeLocked),
    .garageLocked(garageLocked),
    .reset(reset),
    .alarmEnable(alarmEnable),
    .garageAlarm(garageAlarm)
  );

  integer i;

  initial begin
    $dumpfile("burglar_alarm_tb.vcd");
    $dumpvars(0, burglar_alarm_tb);

    // Initial state
    doorState = 8'b00000000;
    windowState = 8'b00000000;
    garageState = 0;
    homeLocked = 0;
    garageLocked = 0;
    reset = 0;
    #5;

    // Lock home and trigger door/window
    homeLocked = 1;
    for (i = 0; i < 8; i = i + 1) begin
      doorState = 8'b00000000;
      windowState = 8'b00000000;
      doorState[i] = 1'b1;
      #2;
    end

    // Trigger window breach
    for (i = 0; i < 8; i = i + 1) begin
      windowState = 8'b00000000;
      doorState = 8'b00000000;
      windowState[i] = 1'b1;
      #2;
    end

    // Unlock home - no alarm should be triggered
    homeLocked = 0;
    doorState = 8'b11111111;
    windowState = 8'b11111111;
    #5;

    // Garage alarm test - locked and opened
    garageLocked = 1;
    garageState = 1;  // garage door opened
    #2;
    garageState = 0;
    #5;

    // Reset the system
    reset = 1;
    #2;
    reset = 0;

    #10;
    $finish;
  end

endmodule
