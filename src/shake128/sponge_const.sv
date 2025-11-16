`timescale 1ns / 1ps
module sponge_const #(
    parameter integer R = 1344 // rate in SHAKE128
)(
    input clk,
    input enable,
    input rst,
    input [255:0] in, // coins or seeds
    input [3:0] domain, // domain separator 1111
    input [13:0] output_len, // output length
    output reg [5375:0] output_string // 5376 bits is the max output we can get in kyber's shake
);
    //initialize
    wire [259:0] in_updated;
    assign in_updated = {domain, in}; // domain || coins/seeds = 260 bits
    wire [R-1:0] padded_mask; //after padding, 1344 bits
    wire [R-1:0] rate_block;
    assign rate_block = {{(R-260){1'b0}}, in_updated}; // place message at LSB of rate block

    // Step 1 : Padding
    padding #(
        .R(R)
    ) pad_inst (
        .input_len(11'd260), // input length in integer (260)
        .block_out(padded_mask) // padded mask
    );
    wire [R-1:0] padded_block = padded_mask ^ rate_block; // concatenate input

    // Step 2 : calculate capacity bits
    localparam integer C = 1600 - R;

    // Step 3 : Absorption phase (only 1 block here, so only absorb once)
    wire [1599:0] absorbed_block;
    assign absorbed_block = {{C{1'b0}}, padded_block};

    // Step 4 : Apply Permutation to state
    wire [1599:0] state_permuted;
    wire perm_valid; // permutation will set valid to 1 when done
    wire perm_enable;
    // only run permutation while global enable is 1 AND permutation is not done
    assign perm_enable = enable & ~perm_valid;
    permutation_sim (
        .clk(clk),
        .enable(perm_enable),
        .rst(rst),
        .state_in(absorbed_block),
        .state_out(state_permuted),
        .valid(perm_valid) // permutation done flag
    );

    // Step 5 : Squeezing phase
    // can support up to 4 blocks of output (4*R = 5376 bits)
    localparam PH_IDLE    = 2'd0;
    localparam PH_PERMUTE = 2'd1;
    localparam PH_SQUEEZE = 2'd2;
    localparam PH_DONE    = 2'd3;
    integer i;
    integer bits_squeezed;
    reg perm_enable;
    reg [1:0] phase; // 0=IDLE, 1=PERMUTE, 2=SQUEEZE, 3=DONE
    reg [1500:0] state_reg;
    // When rst goes high → the always block is triggered, 
    // if (rst) is true, and we set all our registers to known initial values.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase         <= PH_IDLE;
            state_reg     <= 1600'b0;
            bits_squeezed <= 14'd0; // up to 5376 bits
            output_string <= {5376{1'b0}};
            perm_enable   <= 1'b0; 
        end 
        else begin
            case (phase)
                PH_IDLE: begin // if normal
                    if (enable) begin
                        // absorb single block
                        state_reg     <= state_permuted;  // 1600-bit (padded_block || zeros)
                        bits_squeezed <= 14'd0;
                        output_string <= {5376{1'b0}};
                        perm_enable   <= 1'b1; // start first permutation
                        phase         <= PH_PERMUTE;
                end

                PH_PERMUTE: begin // if permutation 
                    if (perm_valid) begin
                        // permutation occurs here
                        state_reg   <= perm_out; // load permuted state
                        phase       <= PH_SQUEEZE;
                    end
                end

                PH_SQUEEZE: begin
                    // copy up to R bits from current state_reg into out_reg
                    for (i = 0; i < R; i = i + 1) begin
                        if ((bits_squeezed + i) < output_len && (bits_squeezed + i) < 5376)
                            output_string[bits_squeezed + i] <= state_reg[i];
                    end

                    // advance bits_squeezed
                    if (output_len - bits_squeezed >= R)
                        bits_squeezed <= bits_squeezed + R;
                    else
                        bits_squeezed <= output_len;

                    // if we still need more bits and haven’t exceeded 4 blocks:
                    if (bits_squeezed < output_len && bits_squeezed < 4*R) begin
                        perm_enable <= 1'b1;      // ask permutation to run again with state_reg
                        phase       <= PH_PERMUTE;
                    end else begin
                        phase <= PH_DONE;         // all requested bits produced
                    end
                end

                PH_DONE: begin
                    // hold out_reg; top can read output_string
                end
            endcase
        end
    end
    // then, cut off output_string to output_len bits only
    
endmodule