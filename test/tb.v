`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    // Explicitly dump the sub-hierarchy for cocotb visibility
    $dumpvars(0, tb.user_project);
    $dumpvars(0, tb.user_project.mac_inst);
    $dumpvars(0, tb.user_project.cordic_inst);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // Replace tt_um_example with your module name:
   tt_um_herald user_project (
      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  // Expose internal instances for direct testing
  // cocotb can access these as dut.mac_inst and dut.cordic_inst
  wire mac_inst_exists = 1'b1;  // Dummy signal to help cocotb find hierarchy
  wire cordic_inst_exists = 1'b1;

  // Create aliases to the internal instances
  // This makes user_project.mac_inst accessible as a testbench-level signal
  // Note: In Icarus Verilog, we rely on hierarchy dumping to make these visible

endmodule
