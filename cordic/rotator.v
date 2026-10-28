`ifndef _ROTATOR_V_
`define _ROTATOR_V_

`default_nettype none

module rotator #(parameter ITERATION=0)
(
    input wire               i_clock,
    input wire               i_aresetn,
    input wire signed [16:0] i_arctan,

    input wire signed [16:0] i_x,
    input wire signed [16:0] i_y,
    input wire signed [16:0] i_theta,

    output reg signed [16:0] o_x,
    output reg signed [16:0] o_y,
    output reg signed [16:0] o_theta
);
    always @(posedge i_clock, negedge i_aresetn)
      if (~i_aresetn)
        begin
          o_x     <= 0;
          o_y     <= 0;
          o_theta <= 0;
        end
      else
        begin
          if (i_theta >= 0)
            begin
              o_x     <= i_x - (i_y >>> ITERATION);
              o_y     <= i_y + (i_x >>> ITERATION);
              o_theta <= i_theta - i_arctan;
            end
          else
            begin
              o_x     <= i_x + (i_y >>> ITERATION);
              o_y     <= i_y - (i_x >>> ITERATION);
              o_theta <= i_theta + i_arctan;
            end
        end
endmodule

`endif // _ROTATOR_V_
