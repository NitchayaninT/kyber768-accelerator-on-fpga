`timescale 1ns / 1ps
`include "params.vh"

// use carry look ahead adder with 12 bits input 13 bits output
// each coefficient in polynomial ring use on cla_adder
// total of 256 cla_adder
// 4rounds of addition is made and then copy value from buffer to output
module add (
    input clk,
    input enable,
    input rst,
    input [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] x[3],  // old syntax is x[0:2]
    input [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] y,
    input [(`KYBER_N * `KYBER_R_WIDTH)-1:0] msg_poly,
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) -1 : 0] e_1[3],
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) -1 : 0] e_2,
    output reg [(`KYBER_N * (`KYBER_R_WIDTH + 1)) - 1 : 0] u[3],
    output reg [(`KYBER_N * (`KYBER_R_WIDTH + 2)) - 1 : 0] v,
    output reg valid,
    output [2:0] debug_state
);

  assign debug_state = state;
  reg [(`KYBER_N * 12) - 1 : 0] in_buf0, in_buf1;
  reg [(`KYBER_N * 13) - 1 : 0] out_buf;
  reg [(`KYBER_N * 12) - 1 : 0] temp;
  reg [(`KYBER_N) - 1 : 0] temp_msb;


  reg [2:0] state;

  // This is cla_adder for compute y + msg_poly
  genvar i;
  generate
    for (i = 0; i < 256; i = i + 1) begin : g_cla_gen
      cla_adder cla_inst (
          .in1(in_buf0[i*12+:12]),
          .in2(in_buf1[i*12+:12]),
          .sum(out_buf[i*13+:13])
      );
    end
  endgenerate


  // seperate in0, and in4 because to avoid invalid state
  multiplexer5x1 mux_uut (
      .selector(state),
      .in0(y),
      .in1(x[0]),
      .in2(x[1]),
      .in3(x[2]),
      .in4(temp),
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

  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
      u[0] <= 0;
      u[1] <= 0;
      u[2] <= 0;
      v <= 0;
      valid <= 0;
    end else if (enable) begin
      case (state)
        3'b000: begin
          integer i;
          for (i = 0; i < 256; i++) begin
            temp[(i*12)+:12] <= out_buf[(i*13)+:12];
            temp_msb[i] <= out_buf[(i*13)+12];
          end
          state <= 3'b001;
        end
        3'b001: begin
          u[0]  <= out_buf;
          state <= 3'b010;
        end
        3'b010: begin
          u[1]  <= out_buf;
          state <= 3'b011;
        end
        3'b011: begin
          u[2]  <= out_buf;
          state <= 3'b100;
        end
        3'b100: begin
          integer i;
          for (i = 0; i < 256; i++) begin
            v[(i*14)+12]  <= temp_msb[i] ^ out_buf[(i*13)+12];  //sum bit
            v[(i*14)+13]  <= temp_msb[i] & out_buf[(i*13)+12];  //carry bit
            v[(i*14)+:12] <= out_buf[(i*13)+:12];  // 12 bits from cla adder
          end
          state <= 3'b101;
        end
        3'b101: begin
          valid <= 1;
          state <= 3'b111;  // wait at invalid state
        end
        default: state <= 3'b111;  // invalid state the output will be 'x
      endcase

    end
  end
endmodule
