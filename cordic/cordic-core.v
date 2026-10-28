`ifndef _CORDIC_CORE_V_
`define _CORDIC_CORE_V_

`default_nettype none

`include "rotator.v"
`include "registers.v"

`timescale 1ns/1ps

module cordic_core(
    input wire                i_clock,
    input wire                i_aresetn,
    input wire signed  [15:0] i_angle,
    output wire signed [15:0] o_sin,
    output wire signed [15:0] o_cos,
    output wire               o_locked,
    output wire signed [15:0] o_angle_delayed
);

  // We use Q2.15 (17 bits) for internal processing
  localparam signed [16:0] K_INVERT = 16'sd19899;
  localparam signed [0:17*15-1] atan_table = {
      17'sd8192, // atan(2^-0)/pi
      17'sd4836, // atan(2^-1)/pi
      17'sd2555,
      17'sd1297,
      17'sd651,
      17'sd326,
      17'sd163,
      17'sd81,
      17'sd41,
      17'sd20,
      17'sd10,
      17'sd5,
      17'sd3,
      17'sd1,
      17'sd1
  };

  wire signed [16:0] x_out         [0:14];
  wire signed [16:0] y_out         [0:14];
  wire signed [16:0] theta_out     [0:14];
  wire signed [16:0] angle_delayed [0:14];

  generate
    genvar i;
    for (i = 0; i < 15; i = i + 1)
      begin
        rotator #(.ITERATION(i)) rotator_i(
            .i_clock   ( i_clock                                ),
            .i_aresetn ( i_aresetn                              ),
            .i_arctan  ( atan_table[i*17 +: 17]                 ),
            .i_x       ( (i == 0) ? K_INVERT : x_out[i - 1]     ),
            .i_y       ( (i == 0) ? 17'b0    : y_out[i - 1]     ),
            .i_theta   ( (i == 0) ? i_angle  : theta_out[i - 1] ),
            .o_x       ( x_out[i]                               ),
            .o_y       ( y_out[i]                               ),
            .o_theta   ( theta_out[i]                           )
        );

        dff_async_rst_n #(.WIDTH(17)) delay_reg(
            .i_clock   ( i_clock                                   ),
            .i_aresetn ( i_aresetn                                 ),
            .i_d       ( (i == 0) ? i_angle : angle_delayed[i - 1] ),
            .o_q       ( angle_delayed[i]                          )
        );
      end
  endgenerate

  shift_reg #(.WIDTH(15), .INIT(1'b0)) shift_reg_locked(
      .i_clock   ( i_clock   ),
      .i_aresetn ( i_aresetn ),
      .i_data    ( 1'b1      ),
      .o_data    ( o_locked  )
  );

  function automatic signed [15:0] convert_to_Q1_15;
    input signed [16:0] i_q2_15;

    begin
      if (i_q2_15 > 17'sd32767)
        convert_to_Q1_15 = 16'sd32767;
      else if (i_q2_15 < -17'sd32768)
        convert_to_Q1_15 = -16'sd32768;
      else
        convert_to_Q1_15 = i_q2_15[15:0];
    end
  endfunction

  // Convert internal Q2.15 to Q1.15 output
  assign o_angle_delayed = convert_to_Q1_15(angle_delayed[14]);
  assign o_cos           = convert_to_Q1_15(x_out[14]);
  assign o_sin           = convert_to_Q1_15(y_out[14]);

endmodule


module test_cordic_core();

  reg clock;
  reg aresetn;
//  reg signed [0:15] angle = 16'hE000; // -PI/4
//  reg signed [0:15] angle = 16'd8192; // PI/4
//  reg signed [0:15] angle = 16'hc000;
  reg signed [0:15] angle = 16'd11;

  wire signed [0:15] sin;
  wire signed [0:15] cos;
  wire signed [0:15] angle_delayed;
  wire locked;

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
    #200
    $finish;
  end

  cordic_core dut(
      .i_clock         ( clock         ),
      .i_aresetn       ( aresetn       ),
      .i_angle         ( angle         ),
      .o_sin           ( sin           ),
      .o_cos           ( cos           ),
      .o_locked        ( locked        ),
      .o_angle_delayed ( angle_delayed )
  );

  initial begin
    $dumpfile("test-cordic-core.vcd");
    $dumpvars(0, test_cordic_core);
  end

endmodule

`endif // _CORDIC_CORE_V_
