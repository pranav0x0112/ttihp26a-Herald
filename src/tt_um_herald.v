`default_nettype none

module tt_um_herald (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  assign uio_oe = 8'b11111111;
  assign uio_out = 8'h00;

  // State machine states
  localparam IDLE       = 3'd0;
  localparam LOAD_ARG1  = 3'd1;
  localparam LOAD_ARG2  = 3'd2;
  localparam EXECUTE    = 3'd3;
  localparam WAIT_BUSY  = 3'd4;
  localparam READ_OUT   = 3'd5;

  reg [2:0] state;
  reg [1:0] byte_count;
  
  // Data registers
  reg [31:0] arg1;  // First argument (angle, y, x, or a)
  reg [31:0] arg2;  // Second argument (x or b) - only for 2-arg operations
  reg [2:0]  opcode; // Operation: 0=sin_cos, 1=atan2, 2=sqrt_mag, 3=multiply
  
  
  reg [63:0] result;
  reg [2:0] result_bytes; 

  wire [31:0] cordic_sin_cos_angle;
  wire cordic_EN_sin_cos;
  wire cordic_RDY_sin_cos;
  
  wire [31:0] cordic_atan2_y;
  wire [31:0] cordic_atan2_x;
  wire cordic_EN_atan2;
  wire cordic_RDY_atan2;
  
  wire [31:0] cordic_sqrt_x;
  wire [31:0] cordic_sqrt_y;
  wire cordic_EN_sqrt;
  wire cordic_RDY_sqrt;
  
  wire [31:0] cordic_mult_a;
  wire [31:0] cordic_mult_b;
  wire cordic_EN_mult;
  wire cordic_RDY_mult;
  
  wire cordic_EN_get_sin_cos;
  wire [63:0] cordic_get_sin_cos;
  wire cordic_RDY_get_sin_cos;
  
  wire cordic_EN_get_atan2;
  wire [31:0] cordic_get_atan2;
  wire cordic_RDY_get_atan2;
  
  wire cordic_EN_get_sqrt;
  wire [31:0] cordic_get_sqrt;
  wire cordic_RDY_get_sqrt;
  
  wire cordic_EN_get_mult;
  wire [31:0] cordic_get_mult;
  wire cordic_RDY_get_mult;
  
  wire cordic_busy;
  wire cordic_RDY_busy;

  assign cordic_sin_cos_angle = arg1;
  assign cordic_EN_sin_cos = (state == EXECUTE && opcode == 3'd0);
  
  assign cordic_atan2_y = arg1;
  assign cordic_atan2_x = arg2;
  assign cordic_EN_atan2 = (state == EXECUTE && opcode == 3'd1);
  
  assign cordic_sqrt_x = arg1;
  assign cordic_sqrt_y = arg2;
  assign cordic_EN_sqrt = (state == EXECUTE && opcode == 3'd2);
  
  assign cordic_mult_a = arg1;
  assign cordic_mult_b = arg2;
  assign cordic_EN_mult = (state == EXECUTE && opcode == 3'd3);
  
  // Get result signals
  assign cordic_EN_get_sin_cos = (state == READ_OUT && opcode == 3'd0);
  assign cordic_EN_get_atan2 = (state == READ_OUT && opcode == 3'd1);
  assign cordic_EN_get_sqrt = (state == READ_OUT && opcode == 3'd2);
  assign cordic_EN_get_mult = (state == READ_OUT && opcode == 3'd3);

  reg [7:0] output_byte;
  assign uo_out = output_byte;
  
  always @(*) begin
    case (byte_count)
      2'd0: output_byte = result[7:0];
      2'd1: output_byte = result[15:8];
      2'd2: output_byte = result[23:16];
      2'd3: output_byte = result[31:24];
      default: output_byte = 8'h00;
    endcase
  end

  // Protocol:
  // ui_in[7:5] = command
  //   3'b000 = NOP
  //   3'b001 = SET_OP (ui_in[2:0] = opcode)
  //   3'b010 = LOAD_BYTE_ARG1 (ui_in[1:0] = byte index, ui_in[4:2] = don't care)
  //   3'b011 = LOAD_BYTE_ARG2 (ui_in[1:0] = byte index)
  //   3'b100 = START_COMPUTE
  //   3'b101 = READ_RESULT (ui_in[1:0] = byte index to read)
  //   3'b110 = GET_STATUS (uo_out[0] = busy)

  wire [2:0] cmd = ui_in[7:5];
  wire [1:0] byte_idx = ui_in[1:0];

  // State machine
  always @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
      byte_count <= 2'd0;
      arg1 <= 32'd0;
      arg2 <= 32'd0;
      opcode <= 3'd0;
      result <= 64'd0;
      result_bytes <= 3'd4;
    end else if (ena) begin
      case (state)
        IDLE: begin
          if (cmd == 3'b001) begin
            // SET_OP
            opcode <= ui_in[2:0];
          end else if (cmd == 3'b010) begin
            // LOAD_BYTE_ARG1
            case (byte_idx)
              2'd0: arg1[7:0]   <= ui_in[4:2]; // Actually use bits for data
              2'd1: arg1[15:8]  <= ui_in[4:2];
              2'd2: arg1[23:16] <= ui_in[4:2];
              2'd3: arg1[31:24] <= ui_in[4:2];
            endcase
          end else if (cmd == 3'b011) begin
            // LOAD_BYTE_ARG2
            case (byte_idx)
              2'd0: arg2[7:0]   <= ui_in[4:2];
              2'd1: arg2[15:8]  <= ui_in[4:2];
              2'd2: arg2[23:16] <= ui_in[4:2];
              2'd3: arg2[31:24] <= ui_in[4:2];
            endcase
          end else if (cmd == 3'b100) begin
            // START_COMPUTE
            state <= EXECUTE;
          end else if (cmd == 3'b101) begin
            // READ_RESULT
            state <= READ_OUT;
            byte_count <= byte_idx;
          end
          // cmd == 3'b110 (GET_STATUS) handled by output logic
        end
        
        EXECUTE: begin
          state <= WAIT_BUSY;
        end
        
        WAIT_BUSY: begin
          if (!cordic_busy && cordic_RDY_busy) begin
            case (opcode)
              3'd0: begin // sin_cos
                if (cordic_RDY_get_sin_cos) begin
                  result <= cordic_get_sin_cos;
                  result_bytes <= 3'd7; 
                  state <= IDLE;
                end
              end
              3'd1: begin // atan2
                if (cordic_RDY_get_atan2) begin
                  result[31:0] <= cordic_get_atan2;
                  result[63:32] <= 32'd0;
                  result_bytes <= 3'd4; // 32-bit result
                  state <= IDLE;
                end
              end
              3'd2: begin // sqrt_magnitude
                if (cordic_RDY_get_sqrt) begin
                  result[31:0] <= cordic_get_sqrt;
                  result[63:32] <= 32'd0;
                  result_bytes <= 3'd4;
                  state <= IDLE;
                end
              end
              3'd3: begin // multiply
                if (cordic_RDY_get_mult) begin
                  result[31:0] <= cordic_get_mult;
                  result[63:32] <= 32'd0;
                  result_bytes <= 3'd4;
                  state <= IDLE;
                end
              end
              default: state <= IDLE;
            endcase
          end
        end
        
        READ_OUT: begin
          if (cmd != 3'b101) begin
            state <= IDLE;
          end
        end
        
        default: state <= IDLE;
      endcase
    end
  end

  // Instantiate CORDIC core
  mkCORDICHighLevel cordic_core (
    .CLK(clk),
    .RST_N(rst_n),
    
    .sin_cos_angle(cordic_sin_cos_angle),
    .EN_sin_cos(cordic_EN_sin_cos),
    .RDY_sin_cos(cordic_RDY_sin_cos),
    
    .atan2_y(cordic_atan2_y),
    .atan2_x(cordic_atan2_x),
    .EN_atan2(cordic_EN_atan2),
    .RDY_atan2(cordic_RDY_atan2),
    
    .sqrt_magnitude_x(cordic_sqrt_x),
    .sqrt_magnitude_y(cordic_sqrt_y),
    .EN_sqrt_magnitude(cordic_EN_sqrt),
    .RDY_sqrt_magnitude(cordic_RDY_sqrt),
    
    .multiply_a(cordic_mult_a),
    .multiply_b(cordic_mult_b),
    .EN_multiply(cordic_EN_mult),
    .RDY_multiply(cordic_RDY_mult),
    
    .EN_get_sin_cos(cordic_EN_get_sin_cos),
    .get_sin_cos(cordic_get_sin_cos),
    .RDY_get_sin_cos(cordic_RDY_get_sin_cos),
    
    .EN_get_atan2(cordic_EN_get_atan2),
    .get_atan2(cordic_get_atan2),
    .RDY_get_atan2(cordic_RDY_get_atan2),
    
    .EN_get_sqrt(cordic_EN_get_sqrt),
    .get_sqrt(cordic_get_sqrt),
    .RDY_get_sqrt(cordic_RDY_get_sqrt),
    
    .EN_get_multiply(cordic_EN_get_mult),
    .get_multiply(cordic_get_mult),
    .RDY_get_multiply(cordic_RDY_get_mult),
    
    .busy(cordic_busy),
    .RDY_busy(cordic_RDY_busy)
  );

endmodule
`default_nettype wire