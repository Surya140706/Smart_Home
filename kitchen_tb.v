module kitchen_tb;
  reg stove_state;
  wire chimney;

  kitchen k (
    .stove_state(stove_state),
    .chimney(chimney)
  );

  initial begin  //start
    $dumpfile("kitchen_tb.vcd");
    $dumpvars(0, kitchen_tb);

    // Initial state: stove is OFF
    stove_state = 1'b0;
    #61;                  // Wait to see chimney remains OFF

    // Turn stove ON
    stove_state = 1'b1;
    #20;                  // Chimney should turn ON

    // Turn stove OFF again
    stove_state = 1'b0;
    #90;                  // Chimney should turn OFF after 60 units

    $finish;
  end
endmodule
