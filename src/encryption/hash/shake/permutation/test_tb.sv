module permutation_tb;
  reg  [1599:0] state_out;
  wire [  63:0] state_out_vec[25];

  genvar i;
  generate
    for (i = 0; i < 25; i++) begin
      assign state_out_vec = state_out[i*64+:64];
    end
  endgenerate
endmodule
