// input state has 1600 bits
module keccak_round (
    input clk;
    input enable;
    input rst;
    input  [1599:0] state_in, 
    input  [63:0]   rc_lane, // round constant    
    output [1599:0] state_out
);

    // Unpack state into lanes with 64 bits
    wire [63:0] A_in [0:24]; // Array A_in is stored as 25 lanes, 64 bits per lane
    genvar i;
    generate 
        for (i=0; i<25; i=i+1) begin : unpacking
            assign A_in[i] = state_in[i*64 +: 64]; //assign 64 bits to each lane
        end 
    endgenerate

    // STEP 1 : Theta
    // Get parity of 2 neighbor columns and then XOR with the current column
    // more info in guide.txt
    // C is to store parity of bits within column (each column stores 64 bits of parities)
    // D is to store parity of bits from 2 neighboring columns (stores in 64 bits form, each bit has different neighbor parity)
    wire [63:0] C[0:4], D[0:4]; 

    // assign columns, range from 0-4
    assign C[0] = A_in[0] ^ A_in[5] ^ A_in[10] ^ A_in[15] ^ A_in[20];
    assign C[1] = A_in[1] ^ A_in[6] ^ A_in[11] ^ A_in[16] ^ A_in[21];
    assign C[2] = A_in[2] ^ A_in[7] ^ A_in[12] ^ A_in[17] ^ A_in[22];
    assign C[3] = A_in[3] ^ A_in[8] ^ A_in[13] ^ A_in[18] ^ A_in[23];
    assign C[4] = A_in[4] ^ A_in[9] ^ A_in[14] ^ A_in[19] ^ A_in[24];

    // from the formula "D[x,z] = C[(x-1)mod5,z] XOR C[(x+1)mod5,(z-1)mod w]"
    // Column in focus shifts left by 1, so just C[x-1]
    // Column in focus shifts right and get the bits in bit position - 1, so need to rotate right to get the column of bit position - 1
    function [63:0] ror1; 
        input [63:0] v; 
        begin 
            ror1 = {v[62:0], v[63]}; // rotates left by 1 and 64th bit goes to LSB
        end 
    endfunction
    
    // get the parities of the 64 bits data in these 2 columns 
    assign D[0]=C[4] ^ rol1(C[1]);
    assign D[1]=C[0] ^ rol1(C[2]);
    assign D[2]=C[1] ^ rol1(C[3]);
    assign D[3]=C[2] ^ rol1(C[4]);
    assign D[4]=C[3] ^ rol1(C[0]);

endmodule