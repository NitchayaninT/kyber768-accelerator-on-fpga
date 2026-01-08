module ntt_mux7 (
    input [15:0] in0,
    input [15:0] in1,
    input [15:0] in2,
    input [15:0] in3,
    input [15:0] in4,
    input [15:0] in5,
    input [15:0] in6,
    input [2:0]sel,
    output reg [15:0] out
);

  always @(*) begin
    case (sel)
      3'd0: out = in0;
      3'd1: out = in1;
      3'd2: out = in2;
      3'd3: out = in3;
      3'd4: out = in4;
      3'd5: out = in5;
      3'd6: out = in6;
      default: out = {16{1'bx}};
    endcase
  end
endmodule
