// Behavioral model of PRAWNS_ART macro
// This synthesizes normally, then gets replaced by the hard macro during PnR

`default_nettype none

module PRAWNS_ART (
    input wire clk,
    output reg alive
);

    initial alive = 1'b0;

    always @(posedge clk) begin
        alive <= ~alive;
    end

endmodule
