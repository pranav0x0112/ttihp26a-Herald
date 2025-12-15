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

  // Simple FSM to satisfy synthesis tool
  localparam IDLE = 1'b0;
  localparam ACTIVE = 1'b1;
  
  reg state;
  
  always @(posedge clk) begin
    if (!rst_n)
      state <= IDLE;
    else begin
      case (state)
        IDLE: if (ena) state <= ACTIVE;
        ACTIVE: if (!ena) state <= IDLE;
      endcase
    end
  end

  // CORDIC signals - all connected
  wire [103:0] cordic_result;
  wire cordic_ready, cordic_result_ready, cordic_busy;
  
  mkCORDIC cordic (
    .CLK(clk),
    .RST_N(rst_n),
    .start_x_init(32'h4DBA),
    .start_y_init(32'h0),
    .start_z_init({24'h0, ui_in}),
    .start_mode(2'b00),
    .EN_start(ena && (state == ACTIVE)),
    .RDY_start(cordic_ready),
    .EN_getResult(1'b0),
    .getResult(cordic_result),
    .RDY_getResult(cordic_result_ready),
    .busy(cordic_busy),
    .RDY_busy()
  );

  // MAC signals - all connected
  wire [31:0] mac_result, mac_result_mac;
  wire mac_ready_mult, mac_ready_mac, mac_ready_clear, mac_ready_get_mult, mac_ready_get_mac;
  wire mac_busy;
  
  mkMAC mac (
    .CLK(clk),
    .RST_N(rst_n),
    .multiply_a({24'h0, ui_in}),
    .multiply_b({24'h0, uio_in}),
    .EN_multiply(ena && (state == ACTIVE)),
    .RDY_multiply(mac_ready_mult),
    .EN_get_multiply(1'b0),
    .get_multiply(mac_result),
    .RDY_get_multiply(mac_ready_get_mult),
    .mac_a(32'h0),
    .mac_b(32'h0),
    .EN_mac(1'b0),
    .RDY_mac(mac_ready_mac),
    .EN_get_mac(1'b0),
    .get_mac(mac_result_mac),
    .RDY_get_mac(mac_ready_get_mac),
    .EN_clear_accumulator(1'b0),
    .RDY_clear_accumulator(mac_ready_clear),
    .busy(mac_busy),
    .RDY_busy()
  );

  // Output: lower byte of MAC result
  assign uo_out = mac_result[7:0];

endmodule