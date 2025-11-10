`define NTT_OMEGA 17
module ntt_top (
    input  [3*256-1:0] r [0:2],
    output [(11*256)-1:0] r_ntt
);
    wire [2:0] in0 [0:255];
    wire [2:0] in1 [0:255];
    wire [2:0] in2 [0:255];
    genvar i;
    generate
        for (i = 0; i < 256; i = i+1) begin : g_unpack_input
            assign in0[i] = r[0][i*3 +: 3];
            assign in1[i] = r[1][i*3 +: 3];
            assign in2[i] = r[2][i*3 +: 3];
        end
    endgenerate
endmodule
