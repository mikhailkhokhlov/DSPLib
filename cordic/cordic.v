`ifndef _CORDIC_V_
`define _CORDIC_V_

`default_nettype none

`include "cordic-core.v"
`include "phase-gen.v"
`include "registers.v"

`timescale 1ns/1ps

module cordic(
    input wire           i_clock,
    input wire           i_aresetn,
    output wire          o_locked,
    output signed [15:0] o_sin,
    output signed [15:0] o_cos
);

  wire        [1:0]  quarter;
  wire signed [15:0] phase;
  wire signed [15:0] sin;
  wire signed [15:0] cos;
  wire               locked;

  phase_generator phase_gen0(
      .i_clock   ( i_clock   ),
      .i_aresetn ( i_aresetn ),
      .o_phase   ( phase     ),
      .o_quarter ( quarter   )
  );

  cordic_core cordic_core0(
      .i_clock         ( i_clock   ),
      .i_aresetn       ( i_aresetn ),
      .i_angle         ( phase     ),
      .o_sin           ( sin       ),
      .o_cos           ( cos       ),
      .o_locked        ( locked    ),
      .o_angle_delayed (           )
  );

  wire [1:0] quarter_delay [0:14];

  generate
    genvar i;
    for (i = 0; i < 15; i = i + 1)
       dff_async_rst_n #(.WIDTH(2)) delay_reg(
            .i_clock   ( i_clock                                   ),
            .i_aresetn ( i_aresetn                                 ),
            .i_d       ( (i == 0) ? quarter : quarter_delay[i - 1] ),
            .o_q       ( quarter_delay[i]                          )
        );
  endgenerate

  function signed [15:0] select_quarter_sin(
      input        [1:0]  quarter,
      input signed [15:0] sin_first_quarter);
    begin
      case (quarter)
        2'b00: select_quarter_sin =  sin_first_quarter;
        2'b01: select_quarter_sin =  sin_first_quarter;
        2'b10: select_quarter_sin = -sin_first_quarter;
        2'b11: select_quarter_sin = -sin_first_quarter;
      endcase
    end
  endfunction

  function signed [15:0] select_quarter_cos(
      input        [1:0]  quarter,
      input signed [15:0] cos_first_quarter);
    begin
      case (quarter)
        2'b00: select_quarter_cos =  cos_first_quarter;
        2'b01: select_quarter_cos = -cos_first_quarter;
        2'b10: select_quarter_cos = -cos_first_quarter;
        2'b11: select_quarter_cos =  cos_first_quarter;
      endcase
    end
  endfunction

  assign o_locked = locked;
  assign o_sin = ( locked ? select_quarter_sin( quarter_delay[14], sin ) : 16'b0 );
  assign o_cos = ( locked ? select_quarter_cos( quarter_delay[14], cos ) : 16'b0 );

endmodule


module test_cordic();

  reg clock;
  reg aresetn;

  wire locked;
  wire signed [15:0] sin;
  wire signed [15:0] cos;

  initial begin
    clock = 0;
    forever
      #5 clock = ~clock;
  end

  initial begin
    aresetn = 1'b1;
    #20 aresetn = 1'b0;
    #15 aresetn = 1'b1;
  end

  initial begin
    #2000000
    $finish;
  end

  cordic dut(
      .i_clock   ( clock   ),
      .i_aresetn ( aresetn ),
      .o_locked  ( locked  ),
      .o_sin     ( sin     ),
      .o_cos     ( cos     )
  );

  initial begin
    $dumpfile("test-cordic.vcd");
    $dumpvars(0, test_cordic);
  end

endmodule

`endif // _CORDIC_V_
