module shake (
    input clk,
    input enable,
    input rst,
    input [255:0] in,
    output [1599:0] state_out,
    output valid
);

  reg [4:0] round;
  reg [1599:0] state_buffer;
  wire [1599:0] theta_out;
  wire [1599:0] rho_out;
  wire [1599:0] pi_out;
  wire [1599:0] chi_out;
  wire [1599:0] iota_out;

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
      .state_in (chi_out),
      .state_out(iota_out)
  );

  always @(posedge clk) begin
    if (rst) begin
      round = 5'h00000;
    end
    if (enable) begin
      if (round == 5'h00000) begin
        state_buffer = {1344'h0, in};
      end else begin
        state_buffer <= iout_out;
      end
      round <= round + 1;
    end else if (state == 25) begin
      valid <= 1;
    end
  end
  assign state_out = state_buffer;
endmodule
