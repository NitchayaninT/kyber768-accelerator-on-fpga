`timescale 1ns / 1ps
/* SHA3 is used to hash random 256 bits and Public key*/
module sha3_256 (
    input               clk,
    input               enable,
    input               rst,
    input  [255:0]      in,          // random 256 bits 
    input  [3:0]        domain,      // domain separator 1111
    input  [13:0]       output_len,  // output length 
    output reg [5375:0] output_string, // max 4*R bits
    output reg          done // done flag
);

    // Reorder bytes so that it absorbs left most byte as first byte like in python
    wire [255:0] msg_bits;
    genvar b;
    generate
        for (b = 0; b < 32; b = b + 1) begin : REORDER
            // in python: first input byte is leftmost byte (in[255:248])
            // in verilog : right most byte gets absorbed first
            // Map that to msg_bits[7:0] so in verilog, the leftmost byte will get absorbed first like in python
            assign msg_bits[b*8 +: 8] = in[255-8*b -:8];
            // takes 8 bits starting atindex b*8 going up by 8
            // X[a -: 8] = X[a : a-7]
            // X[a +: 8] = X[a : a+7]
        end
    endgenerate
    
    // Step 0: added domain seperator
    wire [259:0] in_updated;
    assign in_updated[255:0]   = msg_bits;
    assign in_updated[259:256] = domain; 
    // assign in_updated = {domain, in}; // 260 bits

    wire [R-1:0] rate_block;
    assign rate_block = {{(R-260){1'b0}}, in_updated}; // message in LSBs of rate

    // Step 1 : padding
    wire [R-1:0] padded_mask;
    padding #(
        .R(R)
    ) pad_inst (
        .input_len(11'd260), // input length in integer (260)
        .block_out(padded_mask)
    );

    // apply pad mask to get padded block
    wire [R-1:0] padded_block = padded_mask | rate_block;

    // calculate capacity bits 
    localparam integer C = 1600 - R;

    // Step 2 : Absorbion (only once in this case)
    wire [1599:0] absorbed_block;
    assign absorbed_block = {{C{1'b0}}, padded_block};

    // Step 3: Permutation core under FSM control
    // Step 3.1 : Permute once
    // Step 3.2 : Squeeze. If output_len <= bits_squeezed. Stop
        // else, permute again and then squeeze until bits_squeezed = output_len
    localparam PH_IDLE    = 3'd0;
    localparam PH_PERMUTE = 3'd1;
    localparam PH_SQUEEZE = 3'd2;
    localparam PH_ASSIGN = 3'd3;
    localparam PH_DONE    = 3'd4;

    reg  [2:0]    phase;
    reg  [1599:0] state_reg; // current sponge state S
    reg  [13:0]   bits_squeezed; // how many output bits already written
    reg           perm_enable;

    wire [1599:0] perm_out;
    wire          perm_valid;

    // permutation core: takes state_reg, returns perm_out when perm_valid=1
    permutation u_perm (
        .clk      (clk),
        .enable   (perm_enable),
        .rst      (rst),
        .in (state_reg),
        .state_out(perm_out),
        .valid    (perm_valid)
    );

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase         <= PH_IDLE;
            state_reg     <= 1600'b0;
            bits_squeezed <= 14'd0;
            output_string <= {5376{1'b0}}; // initialize output str to 000000...
            perm_enable   <= 1'b0; 
            done          <= 1'b0;
            
        end else begin
            perm_enable <= 1'b0;
            case (phase)
                // 0. Wait for 'enable' to start
                PH_IDLE: begin
                    done <= 1'b0; // clear done when starting a new run
                    if (enable) begin
                        // load absorbed state and start FIRST permutation
                        state_reg     <= absorbed_block; // 1344 bits with 256 security bits
                        bits_squeezed <= 14'd0;
                        output_string <= {5376{1'b0}};
                        phase         <= PH_PERMUTE;
                    end
                end
                // 1. Wait for permutation core to finish
                // problem : it changes phase to PH_SQUEEZE, but doesnt permute, perm_valid never enables
                PH_PERMUTE: begin
                    perm_enable   <= 1'b1; // enable permutation (step 3.1)
                    if (perm_valid) begin // if finished 24 rounds 
                        // S <- f(S)
                        state_reg   <= perm_out; 
                       // perm_enable <= 1'b0; // stop permutation, then go squeeze
                        // perm_enable will automatically go back to 0 next cycle
                        phase       <= PH_SQUEEZE;
                    end
                end

                // 2. Squeeze up to 1344 bits from current state_reg
                PH_SQUEEZE: begin
                    // copy the next block of bits from the rate part of S
                    for (i = 0; i < R; i = i + 1) begin
                        if ((bits_squeezed + i) < output_len)
                            output_string[bits_squeezed + i] <= state_reg[i];
                    end 
                // 3. After we've squeezed, keep track of the bits we've squeezed and continue with the next round if output len is more than 1344
                    // advance how many bits we've squeezed so far
                    if (output_len - bits_squeezed >= R)
                        bits_squeezed <= bits_squeezed + R; // for seeds (5376 bits)
                    else
                        bits_squeezed <= output_len; // for coins (1024 bits), which is less than R
                     phase <= PH_ASSIGN;
                  end
                  
                PH_ASSIGN: begin
                    // if more bits are needed and we haven't exceeded 4 blocks
                    if (bits_squeezed < output_len && bits_squeezed < 4*R) begin
                        //perm_enable <= 1'b1;   // run permutation again on the current state_reg
                        phase       <= PH_PERMUTE;
                    end else begin
                        phase       <= PH_DONE; // we're done
                    end
                end

                // 4. Done
                PH_DONE: begin
                    done <= 1'b1;
                    // can read output_string now
                end
            endcase
        end
    end
endmodule