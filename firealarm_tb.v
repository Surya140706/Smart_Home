module fireAlarm_tb;
  reg [2:0] smoke_detector_3bit;        // 3-bit input for testing
  wire alarmEnable;

  // Padding 3-bit to 8-bit by prepending 0s
  fire_alarm f (
    .smoke_detector({5'd0, smoke_detector_3bit}),
    .alarmEnable(alarmEnable)
  );

  integer i;

  initial begin
    $dumpfile("fire_alarm_tb.vcd");     // VCD waveform output
    $dumpvars(0, fireAlarm_tb);         // Dump all signals in this testbench

    // Test increasing smoke levels
    for (i = 0; i < 8; i = i + 1) begin
      smoke_detector_3bit = i[2:0];     // Use 3-bit slice of integer
      #2;
    end

    // Test decreasing smoke levels
    for (i = 7; i >= 0; i = i - 1) begin
      smoke_detector_3bit = i[2:0];
      #2;
    end

    $finish;
  end
endmodule
