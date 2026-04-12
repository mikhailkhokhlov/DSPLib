`ifndef _PHASE_GEN_V_
`define _PHASE_GEN_V_

`default_nettype none

`timescale 1ns/1ps

module phase_generator(
    input wire                i_clock,
    input wire                i_aresetn,
    output wire signed [15:0] o_phase,
    output wire        [1:0]  o_quarter
);

  localparam FIRST  = 2'b00;
  localparam SECOND = 2'b01;
  localparam THIRD  = 2'b10;
  localparam FORTH  = 2'b11;

  reg [1:0] reg_state;
  reg [1:0] next_state;

  reg signed [15:0] reg_phase;
  reg signed [15:0] reg_delta;

  always @(posedge i_clock or negedge i_aresetn)
    if (~i_aresetn)
      reg_state <= FIRST;
    else
      reg_state <= next_state;

  always @(posedge i_clock or negedge i_aresetn)
    if (~i_aresetn)
      reg_phase <= 16'b0;
    else
      reg_phase <= reg_phase + reg_delta;

  always @(*)
    case (reg_state)
      FIRST : next_state = (reg_phase >= 16'h4000 - reg_delta) ? SECOND : FIRST;
      SECOND: next_state = (reg_phase <= 16'h0000 - reg_delta) ? THIRD  : SECOND;
      THIRD : next_state = (reg_phase >= 16'h4000 - reg_delta) ? FORTH  : THIRD;
      FORTH : next_state = (reg_phase <= 16'h0000 - reg_delta) ? FIRST  : FORTH;
    endcase

  always @(*)
    case (reg_state)
      FIRST : reg_delta =  16'b1;
      SECOND: reg_delta = -16'b1;
      THIRD : reg_delta =  16'b1;
      FORTH : reg_delta = -16'b1;
    endcase

  assign o_phase   = reg_phase;
  assign o_quarter = reg_state;

endmodule


module test_phase_generator();

  reg clock;
  reg aresetn;

  wire signed [15:0] phase;
  wire [1:0] quarter;

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

  phase_generator dut(
      .i_clock   ( clock   ),
      .i_aresetn ( aresetn ),
      .o_phase   ( phase   ),
      .o_quarter ( quarter )
  );

  initial begin
    $dumpfile("test-phase-gen.vcd");
    $dumpvars(0, test_phase_generator);
  end

endmodule

`endif // _PHASE_GEN_V_
