`timescale 1ns / 1ps
`include "params.vh"

// use carry look ahead adder with 12 bits input 13 bits output
// each coefficient in polynomial ring use on cla_adder
// total of 256 cla_adder
// 4rounds of addition is made and then copy value from buffer to output
module add (
    input clk,
    input enable,
    input [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] x[3],  // old syntax is x[0:2]
    input [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] y,
    input [(`KYBER_N * `KYBER_R_WIDTH)-1:0] msg_poly,
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) -1 : 0] e_1[3],
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) -1 : 0] e_2,
    output reg [(`KYBER_N * (`KYBER_R_WIDTH + 1)) - 1 : 0] u[3],
    output reg [(`KYBER_N * (`KYBER_R_WIDTH + 1)) - 1 : 0] v,
    output reg valid
);

  reg [(`KYBER_N * 12) - 1 : 0] in_buf0, in_buf1;
  reg [(`KYBER_N * 13) - 1 : 0] out_buf;

  reg [2:0] state;

  // This is cla_adder for compute y + msg_poly
  cla_adder cla_adder0 (
      .in1(in_buf0),
      .in2(in_buf1),
      .sum(out_buf)
  );

  // seperate in0, and in4 because to avoid invalid state
  multiplexer5x1 mux_uut (
      .selector(state),
      .in0(y),
      .in1(x[0]),
      .in2(x[1]),
      .in3(x[2]),
      .in4(v),
      .out(in_buf0)
  );

  multiplexer5x1_small mux_small_uut (
    .selector(state),
      .in0(e_2),
      .in1(e_1[0]),
      .in2(e_1[1]),
      .in3(e_1[2]),
      .in4(msg_poly),
      .out(in_buf1)
  );

  genvar i;
  always @(posedge clk) begin
    if (enable) begin
      case (state)
        3'd000: begin
          v = out_buf;
          state = 3'd001;
        end
        3'b001: begin
          u[0] = out_buf;
          state = 3'b010;
        end
        3'b010: begin
          u[0] = out_buf;
          state = 3'b011;
        end
        3'b011: begin
          u[0] = out_buf;
          state = 3'b100;
        end
        3'b100: begin
          u[0] = out_buf;
          state = 3'b101;
        end
        3'b101: valid = 0;
        default: e_1 <= 'x;
      endcase

    end
  end
endmodule
