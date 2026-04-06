`ifndef _REGISTERS_V_
`define _REGISTERS_V_

`default_nettype none

module dff_async_rst_n #(
    parameter WIDTH = 32,
    parameter INIT  = {WIDTH{1'b0}}
)
(
    input                      i_clock,
    input                      i_aresetn,
    input      [(WIDTH - 1):0] i_d,
    output reg [(WIDTH - 1):0] o_q);

  always @(posedge i_clock or negedge i_aresetn)
    if (~i_aresetn)
      o_q <= INIT;
    else
      o_q <= i_d;

endmodule


module shift_reg #(
    parameter WIDTH = 15,
    parameter [(WIDTH - 1):0] INIT = {WIDTH{1'b0}}
)
(
    input  wire i_clock,
    input  wire i_aresetn,
    input  wire i_data,
    output wire o_data
);

  reg [(WIDTH-1):0] shift_reg;

  always @(posedge i_clock) begin
      if (~i_aresetn)
        shift_reg <= INIT;
      else
        shift_reg <= {shift_reg[(WIDTH-2):0], i_data};
  end

  assign o_data = shift_reg[WIDTH-1];

endmodule

`endif // _REGISTERS_V_
