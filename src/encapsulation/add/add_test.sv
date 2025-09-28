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
            v[(i*14)+12]  <= temp_msb[i] ^ out_buf[(i*13)+12];  //carry bit
            v[(i*14)+13]  <= temp_msb[i] & out_buf[(i*13)+12];  //sum bit
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


module cla_adder #(
    parameter int DATA_WID = 12
) (
    in1,
    in2,
    //carry_in,
    sum
    //carry_out// we will use this carry out for the last sum from v=y+msg_poly+e_2;
);

  input [DATA_WID - 1:0] in1;
  input [DATA_WID - 1:0] in2;
  //input carry_in;
  output [DATA_WID:0] sum;
  output carry_out;

  wire [DATA_WID - 1:0] gen;
  wire [DATA_WID - 1:0] pro;
  wire [DATA_WID:0] carry_tmp;

  genvar j, i;
  generate
    //assume carry_tmp in is zero
    assign carry_tmp[0] = 0;  //carry_in;

    //carry generator
    for (j = 0; j < DATA_WID; j = j + 1) begin : g_carry
      assign gen[j] = in1[j] & in2[j];
      assign pro[j] = in1[j] | in2[j];
      assign carry_tmp[j+1] = gen[j] | pro[j] & carry_tmp[j];
    end

    for (i = 0; i < DATA_WID; i = i + 1) begin : g_sum_without_carry
      assign sum[i] = in1[i] ^ in2[i] ^ carry_tmp[i];
    end

    //assign carry_out = carry_tmp[DATA_WID];
    assign sum[DATA_WID] = carry_tmp[DATA_WID];
  endgenerate
endmodule

module multiplexer5x1 (
    input [2:0] selector,
    input [(`KYBER_N * 12) - 1 : 0] in0,
    input [(`KYBER_N * 12) - 1 : 0] in1,
    input [(`KYBER_N * 12) - 1 : 0] in2,
    input [(`KYBER_N * 12) - 1 : 0] in3,
    input [(`KYBER_N * 12) - 1 : 0] in4,
    output reg [(`KYBER_N * 12) - 1 : 0] out
);

  always_comb begin
    case (selector)
      0: out = in0;
      1: out = in1;
      2: out = in2;
      3: out = in3;
      4: out = in4;
      default: out = 'x;
    endcase
  end
endmodule

module multiplexer5x1_small (
    input [2:0] selector,
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) - 1 : 0] in0,
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) - 1 : 0] in1,
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) - 1 : 0] in2,
    input [(`KYBER_N * `KYBER_SPOLY_WIDTH) - 1 : 0] in3,
    input [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] in4,  // normal size polynomials
    output reg [(`KYBER_N * `KYBER_R_WIDTH) - 1 : 0] out
);

  logic [`KYBER_SPOLY_WIDTH-1:0] coeff;
  integer i;
  always_comb begin
    if (selector == 4) begin
      out = in4;  // pass-through full polynomial
    end else begin
      for (i = 0; i < `KYBER_N; i = i + 1) begin
        logic [`KYBER_SPOLY_WIDTH-1:0] coeff;
        case (selector)
          0: coeff = in0[i*`KYBER_SPOLY_WIDTH+:`KYBER_SPOLY_WIDTH];
          1: coeff = in1[i*`KYBER_SPOLY_WIDTH+:`KYBER_SPOLY_WIDTH];
          2: coeff = in2[i*`KYBER_SPOLY_WIDTH+:`KYBER_SPOLY_WIDTH];
          3: coeff = in3[i*`KYBER_SPOLY_WIDTH+:`KYBER_SPOLY_WIDTH];
          default: coeff = 'x;
        endcase

        // Expand small coefficient to 12-bit
        out[i*`KYBER_R_WIDTH+:`KYBER_R_WIDTH] = (coeff == 3'b111) ? `KYBER_Q - 1 :  //3328
        (coeff == 3'b110) ? `KYBER_Q - 2 :  //3327
        coeff;  // 0,1,2
      end
    end
  end
endmodule
