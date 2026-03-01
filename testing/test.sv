module test (
    input clk,
    reset,
    enable,
    input [5:0] a[16],
    output logic [5:0] r_wire,
    output logic [5:0] r_reg
);
  logic [3:0] index;

  always_comb begin
    r_wire = 'h0;
    if (enable) begin
      r_wire = a[index];
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      index <= 0;
      r_reg <= 0;
    end else if (enable) begin
      r_reg <= a[index];
      index <= index + 1;
    end
  end
endmodule
