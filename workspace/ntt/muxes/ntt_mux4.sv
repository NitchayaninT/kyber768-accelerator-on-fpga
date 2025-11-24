module ntt_mux4 (
    input [15:0] in0,
    input [15:0] in1,
    input [15:0] in2,
    input [15:0] in3,
    input [1:0]sel,
    output reg [15:0] out
);

  always @(*) begin
    case (sel)
      2'd0: out = in0;
      2'd1: out = in1;
      2'd2: out = in2;
      2'd3: out = in3;
      default: out = {16{1'bx}};
    endcase
  end
endmodule
