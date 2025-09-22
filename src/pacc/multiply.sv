module multiply #(
  parameter int WIDTH = 8
)(
  input [WIDTH-1:0]  in1,
  input [WIDTH-1:0]  in2,
  output [(2*WIDTH)-1:0] out
);
  // Just place holder before optimize the multiplcation implementations
  always_comb begin
      out = in1 * in2;
  end
endmodule
