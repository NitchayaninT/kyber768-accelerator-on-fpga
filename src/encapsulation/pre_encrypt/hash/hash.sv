module sha3_256 #(
    parameter int IN_WIDTH = KYBER_N
) (
    input clk,
    input wire start,
    input wire [IN_WIDTH-1:0] in,
    output reg [KYBER_N:0] out,
    output reg valid  // use for signalling start stop signal
);
  // place holder
  always @(posedge clk) begin
    if (start) begin
      out <= in;
      valid <= 1'b1;
    end
    else begin
      valid <= 1'b0;
    end
  end
endmodule

module sha3_512 #(
    parameter int IN_WIDTH = 2 * KYBER_N
) (
    input clk,
    input wire start,
    input wire [IN_WIDTH-1:0] in,
    output reg [(2 * KYBER_N)-1:0] out,
    output reg valid  // use for signalling start stop signal
);
  always @(posedge clk) begin
    if (start) begin
      out <= in;
      valid <= 1'b1;
    end
    else begin
      valid <= 1'b0;
    end
  end
endmodule
