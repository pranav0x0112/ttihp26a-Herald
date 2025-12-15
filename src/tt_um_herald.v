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

  // Set all IOs as outputs
  assign uio_oe = 8'hFF;
  assign uio_out = 8'h00;

  // Explicit 2-state FSM for synthesis tool
  reg state_reg;
  wire state_next;
  
  localparam STATE_IDLE = 1'b0;
  localparam STATE_ACTIVE = 1'b1;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_reg <= STATE_IDLE;
    end else begin
      state_reg <= state_next;
    end
  end
  
  assign state_next = (state_reg == STATE_IDLE) ? (ena ? STATE_ACTIVE : STATE_IDLE) :
                      (state_reg == STATE_ACTIVE) ? (ena ? STATE_ACTIVE : STATE_IDLE) :
                      STATE_IDLE;

  // CORDIC module - ALL ports connected
  wire [103:0] cordic_result_wire;
  wire cordic_rdy_start_wire;
  wire cordic_rdy_result_wire;
  wire cordic_busy_wire;
  wire cordic_rdy_busy_wire;
  
  mkCORDIC cordic_inst (
    .CLK(clk),
    .RST_N(rst_n),
    .start_x_init(32'h00004DBA),
    .start_y_init(32'h00000000),
    .start_z_init({24'h000000, ui_in}),
    .start_mode(2'b00),
    .EN_start(ena & state_reg),
    .RDY_start(cordic_rdy_start_wire),
    .EN_getResult(1'b0),
    .getResult(cordic_result_wire),
    .RDY_getResult(cordic_rdy_result_wire),
    .busy(cordic_busy_wire),
    .RDY_busy(cordic_rdy_busy_wire)
  );

  // MAC module - ALL ports connected
  wire [31:0] mac_get_multiply_wire;
  wire [31:0] mac_get_mac_wire;
  wire mac_rdy_multiply_wire;
  wire mac_rdy_get_multiply_wire;
  wire mac_rdy_mac_wire;
  wire mac_rdy_get_mac_wire;
  wire mac_rdy_clear_wire;
  wire mac_busy_wire;
  wire mac_rdy_busy_wire;
  
  mkMAC mac_inst (
    .CLK(clk),
    .RST_N(rst_n),
    .multiply_a({24'h000000, ui_in}),
    .multiply_b({24'h000000, uio_in}),
    .EN_multiply(ena & state_reg),
    .RDY_multiply(mac_rdy_multiply_wire),
    .EN_get_multiply(1'b0),
    .get_multiply(mac_get_multiply_wire),
    .RDY_get_multiply(mac_rdy_get_multiply_wire),
    .mac_a(32'h00000000),
    .mac_b(32'h00000000),
    .EN_mac(1'b0),
    .RDY_mac(mac_rdy_mac_wire),
    .EN_get_mac(1'b0),
    .get_mac(mac_get_mac_wire),
    .RDY_get_mac(mac_rdy_get_mac_wire),
    .EN_clear_accumulator(1'b0),
    .RDY_clear_accumulator(mac_rdy_clear_wire),
    .busy(mac_busy_wire),
    .RDY_busy(mac_rdy_busy_wire)
  );

  // Output assignment
  assign uo_out = mac_get_multiply_wire[7:0];

endmodule