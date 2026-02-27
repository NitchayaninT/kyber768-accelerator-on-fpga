`include "params.vh"

module pacc (
    input logic clk,
    input logic we,
    input logic en,
    output logic signed [31:0] r[12]
);

  logic [6:0] addra = 0;
  logic [6:0] addrb = 0;
  logic signed [31:0] dia = 0;
  logic signed [31:0] dib = 0;

  logic signed [31:0] douta[12];
  logic signed [31:0] doutb[12];

  // simple counter so addresses toggle
  always_ff @(posedge clk) begin
    addra <= addra + 1;
    addrb <= addrb + 1;
  end

  genvar g;
  generate
    for (g = 0; g < 12; g++) begin : GEN_RAM
      rams_dp_nc u_ram (
          .clk  (clk),
          .wea  (we),
          .web  (we),
          .ena  (en),
          .enb  (en),
          .addra(addra),
          .addrb(addrb),
          .dia  (dia),
          .dib  (dib),
          .douta(douta[g]),
          .doutb(doutb[g])
      );

      assign r[g] = douta[g];
    end
  endgenerate
endmodule
