`default_nettype none

module tt_um_herald (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  assign uio_oe = 8'hFF;
  assign uio_out = 8'h00;

  // CORDIC wires
  wire [103:0] cordic_result;
  wire cordic_rdy_start, cordic_rdy_result, cordic_busy, cordic_rdy_busy;
  
  // CORDIC instance
  mkCORDIC cordic_inst (
    .CLK(clk),
    .RST_N(rst_n),
    .start_x_init(32'h00004DBA),
    .start_y_init(32'h00000000),
    .start_z_init({24'h000000, ui_in}),
    .start_mode(2'b00),
    .EN_start(ena),
    .RDY_start(cordic_rdy_start),
    .EN_getResult(1'b0),
    .getResult(cordic_result),
    .RDY_getResult(cordic_rdy_result),
    .busy(cordic_busy),
    .RDY_busy(cordic_rdy_busy)
  );

  // MAC wires
  wire [31:0] mac_multiply_result, mac_mac_result;
  wire mac_rdy_multiply, mac_rdy_get_multiply;
  wire mac_rdy_mac, mac_rdy_get_mac;
  wire mac_rdy_clear, mac_busy, mac_rdy_busy;
  
  // MAC instance
  mkMAC mac_inst (
    .CLK(clk),
    .RST_N(rst_n),
    .multiply_a({24'h000000, ui_in}),
    .multiply_b({24'h000000, uio_in}),
    .EN_multiply(ena),
    .RDY_multiply(mac_rdy_multiply),
    .EN_get_multiply(1'b0),
    .get_multiply(mac_multiply_result),
    .RDY_get_multiply(mac_rdy_get_multiply),
    .mac_a(32'h00000000),
    .mac_b(32'h00000000),
    .EN_mac(1'b0),
    .RDY_mac(mac_rdy_mac),
    .EN_get_mac(1'b0),
    .get_mac(mac_mac_result),
    .RDY_get_mac(mac_rdy_get_mac),
    .EN_clear_accumulator(1'b0),
    .RDY_clear_accumulator(mac_rdy_clear),
    .busy(mac_busy),
    .RDY_busy(mac_rdy_busy)
  );

  assign uo_out = mac_multiply_result[7:0];

endmodule