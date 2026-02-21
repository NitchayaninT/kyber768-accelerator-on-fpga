module shake256 #(
    parameter integer R = 1088 // rate in SHAKE256
)(
    input               clk,
    input               enable,
    input               rst,
    input  [511:0]      in,          // coins
    input  integer      input_len,
    input  [7:0]        nonce,       // 1 byte input
    input  [13:0]       output_len,  // output length
    output reg [1023:0] output_string, // max 4*R bits
    output reg          done // done flag
);
    logic [R-1:0] rate_block;    
    integer i;
    always @* begin
        rate_block = '0;

        if (input_len == 512) begin
            // KDF: use all 512 bits, no nonce
            for (i = 0; i < 512/8; i++) begin
                rate_block[i*8 +: 8] = in[511-8*i -:8];
                //rate_block[8*i +: 8] = msg_bits[8*i +: 8];
            end
            // suffix after message
            rate_block[512 +: 8] = rate_block[512 +: 8] ^ 8'h1F;
        end
        else begin
            // coins case: use input_len bits from in (usually 256)
             for (i = 0; i < 256/8; i++) begin
                rate_block[8*i +: 8] = in[8*i +:8];
            end
            // append nonce right after message bits
            rate_block[input_len +: 8] = nonce;

            // suffix after message+nonce
            rate_block[(input_len+8) +: 8] = rate_block[(input_len+8) +: 8] ^ 8'h1F;
        end
        // pad10*1: final bit of the rate
        rate_block[R-1] = 1'b1;
    end

    // calculate capacity bits 
    localparam integer C = 1600 - R;

    // Step 2 : Absorption (only once in this case)
    wire [1599:0] absorbed_block;
    assign absorbed_block = {{C{1'b0}}, rate_block};

    // Step 3: Permutation core under FSM control
    // Step 3.1 : Permute once
    // Step 3.2 : Squeeze. If output_len <= bits_squeezed. Stop
        // else, permute again and then squeeze until bits_squeezed = output_len
    localparam PH_IDLE    = 3'd0;
    localparam PH_PERMUTE = 3'd1;
    localparam PH_SQUEEZE = 3'd2;
    localparam PH_ASSIGN = 3'd3;
    localparam PH_DONE   = 3'd4;
    localparam PH_CLEAR = 3'd5;

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
        .in       (state_reg),
        .state_out(perm_out),
        .valid    (perm_valid)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase         <= PH_IDLE;
            state_reg     <= 1600'b0;
            bits_squeezed <= 14'd0;
            output_string <= {1024{1'b0}}; // initialize output str to 000000...
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
                        output_string <= {1024{1'b0}};
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
                    output_string[bits_squeezed +: R] <= state_reg[0 +: R];
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
                    phase <= PH_CLEAR;
                    // can read output_string now
                end

                PH_CLEAR: begin
                    if(enable) begin
                        phase <= PH_IDLE;
                        done <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule