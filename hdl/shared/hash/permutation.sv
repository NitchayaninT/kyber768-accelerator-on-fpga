`timescale 1ns/1ps
module permutation (
    input clk,
    input enable,
    input rst,
    input [1599:0] in,
    output [1599:0] state_out,
    output reg valid
);

  reg [4:0] round;
  reg [1599:0] state_buffer;
  wire [1599:0] theta_out;
  wire [1599:0] rho_out;
  wire [1599:0] pi_out;
  wire [1599:0] chi_out;
  wire [1599:0] iota_out;

  // round index for iota (5-bit, sized)
  wire [4:0] ir_w = round - 1;

  theta theta_uut (
      .state_in (state_buffer),
      .state_out(theta_out)
  );

  rho rho_uut (
      .state_in (theta_out),
      .state_out(rho_out)
  );

  pi pi_uut (
      .state_in (rho_out),
      .state_out(pi_out)
  );
  chi chi_uut (
      .state_in (pi_out),
      .state_out(chi_out)
  );

  iota iota_uut (
      .state_in(chi_out),
      .state_out(iota_out),
      .ir(ir_w)
  );

  assign state_out = state_buffer;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      round <= 5'h00;
      valid <= 0;
      state_buffer <= 1600'h0;  // ← Initialize to avoid X's
    end else if (!enable) begin
      round <= 5'h00;
      valid <= 1'b0;
    end else begin
      // permutation active
      if (round == 5'h00) begin
        state_buffer <= {in};  // Load input
        round <= round + 1;
        valid <= 1'b0;
      end else if (round <= 24) begin  // ← Rounds 1-24 (24 Keccak rounds)
        state_buffer <= iota_out;
        round <= round + 1;
        if (round == 24) begin  // ← After 24th round completes
          valid <= 1;
        end
      end else begin
        valid <= 1'b1;  // hold output and keep valid high
      end
    end
  end
endmodule
