module airConditioning_tb();
  reg [6:0] temperature;
  reg humanDetector;
  wire heater, airConditioner;
  wire [1:0] fan_speed;

  // Instantiate the module under test
  airConditioning uut (
    .temperature(temperature),
    .humanDetector(humanDetector),
    .heater(heater),
    .airConditioner(airConditioner),
    .fan_speed(fan_speed)
  );

  integer i;

  initial begin
    // Generate waveform output
    $dumpfile("airConditioning_tb.vcd");   // Name of VCD file
    $dumpvars(0, airConditioning_tb);      // Dump all variables in this module

    // Test with human present
    humanDetector = 1'b1;
    for (i = 0; i < 128; i = i + 1) begin
      temperature = i;
      #1;
    end
    for (i = 127; i >= 0; i = i - 1) begin
      temperature = i;
      #1;
    end

    // Test with human absent
    humanDetector = 1'b0;
    for (i = 0; i < 128; i = i + 1) begin
      temperature = i;
      #1;
    end
    for (i = 127; i >= 0; i = i - 1) begin
      temperature = i;
      #1;
    end

    $finish;  // End simulation
  end
endmodule
