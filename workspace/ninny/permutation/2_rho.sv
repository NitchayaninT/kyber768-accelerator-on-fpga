// input state has 1600 bits
module rho (
    input clk,
    input enable,
    input rst,
    input  [1599:0] state_in,    
    output [1599:0] state_out
);
    // Unpack state into lanes with 64 bits
    wire [63:0] A_in [0:24];  
    wire [63:0] A_out [0:24];
    genvar i;
    generate 
        for (i=0; i<25; i=i+1) begin : unpacking
            assign A_in[i] = state_in[i*64 +: 64]; //assign 64 bits to each lane
        end 
    endgenerate

    // Len 0 stays the same
    assign A_out[0] = A_in[0];
    
    // function rotate left
    function rol;
        input [63:0] bit;
        begin
            
