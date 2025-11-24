module ntt_mux2 (
    input [15:0] in0,
    input [15:0] in1,
    input sel,
    output reg [15:0] out
);

  always @(*) begin
    case (sel)
      1'd0: out = in0;
      1'd1: out = in1;
      default: out = {16{1'bx}};
    endcase
  end
endmodule
