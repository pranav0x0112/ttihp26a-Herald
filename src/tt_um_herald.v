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

  // CORDIC
  wire [103:0] cordic_result;
  
  mkCORDIC cordic (
    .CLK(clk), .RST_N(rst_n),
    .start_x_init(32'h4DBA), .start_y_init(32'h0),
    .start_z_init({24'h0, ui_in}), .start_mode(2'b00),
    .EN_start(ena), .RDY_start(),
    .getResult(cordic_result), .RDY_getResult(), .EN_getResult(ena),
    .busy(), .RDY_busy()
  );

  // MAC
  wire [31:0] mac_result;
  
  mkMAC mac (
    .CLK(clk), .RST_N(rst_n),
    .multiply_a({24'h0, ui_in}), .multiply_b({24'h0, uio_in}),
    .EN_multiply(ena), .RDY_multiply(),
    .get_multiply(mac_result), .RDY_get_multiply(), .EN_get_multiply(ena),
    .mac_a(32'h0), .mac_b(32'h0),
    .EN_mac(1'b0), .RDY_mac(),
    .get_mac(), .RDY_get_mac(), .EN_get_mac(1'b0),
    .EN_clear_accumulator(1'b0), .RDY_clear_accumulator(),
    .busy(), .RDY_busy()
  );

  assign uo_out = mac_result[7:0];

endmodule