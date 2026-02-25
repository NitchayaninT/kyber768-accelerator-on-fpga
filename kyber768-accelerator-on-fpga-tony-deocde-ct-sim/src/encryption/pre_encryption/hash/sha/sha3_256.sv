`timescale 1ns / 1ps
/* SHA3-256 sponge wrapper (Keccak-f[1600]) */
/* capacity c = 512, rate r = 1088 (136 bytes) */
/* output = 256 bits */

module sha3_256 #(
    parameter integer R = 1088
)(
    input               clk,
    input               enable,
    input               rst,
    input  [9471:0]     in,          // if 9472 = PK, if 256 = random bits
    input  [13:0]       input_len,   // 9472 or 256 (bits)
    output reg [255:0]  output_string,
    output reg          done
);

    localparam integer C = 512; //capacity bits specified in NIST FIPS 202
    localparam integer RATE_BYTES = R/8;   // 136 bytes

    // Convert bits->bytes 
    wire [10:0] msg_len_bytes = input_len[13:3]; // 9472->1184, 256->32

    // SHA3 padding suffix byte (SHA3 uses 0x06)
    localparam [7:0] SHA3_SUFFIX = 8'h06; // 101 -> gets from 0x06 + pad 1

    // Function to get python order
    // - For PK: reverse across 1184 bytes (in[9471:0])
    // - For 256-bit R: reverse across 32 bytes (in[255:0])
    // its reversed so that leftmost byte is absorbed first like in pythoon
    function automatic [7:0] get_msg_byte(input integer idx); //idx is from 0-max byte
        begin
            if (input_len == 14'd256) begin
                get_msg_byte = in[255-8*idx -: 8];
            end else begin
                get_msg_byte = in[9471-8*idx -: 8];
            end
        end
    endfunction

    // Calculate number of absorption blocks (1 or 9):
    // append 1 byte suffix (for padding later), 0101 will be padded
    // total bytes = number of message bytes AFTER padding (+1 byte)
    // blocks = (total_bytes / RATE_BYTES) rounded up
    wire [11:0] total_bytes = {1'b0,msg_len_bytes} + 12'd1; // msg_len_bytes + 1 byte for suffix (this is to keep total no. of bytes to absorb)
    wire [7:0]  num_blocks  = (total_bytes + RATE_BYTES - 1) / RATE_BYTES; // 1 or 9
    wire [7:0]  last_block  = (num_blocks == 0) ? 8'd0 : (num_blocks - 1); // if num_blocks=0, last_block=0 else num_blocks-1 (8)

    // Build current rate block for absorb_idx (combinational)
    reg [R-1:0] rate_block; //1088 bits

    // Absorb msg to block(s)
    integer j;
    reg [11:0] total_bytes_index;
    reg [7:0]  absorb_byte;
    reg [7:0]  absorb_idx; // absorbed BLOCK index (0 to num_blocks-1)

    always @* begin
        rate_block = {R{1'b0}}; //1088 bits zero
        for (j = 0; j < RATE_BYTES; j = j + 1) begin // stops absorbing when it exceeds the rate byte (1088/8 bytes)
            total_bytes_index = absorb_idx * RATE_BYTES + j; // start from 0 until it stops absorbing
            // it iterates every block until all blocks absorbed. 
            // total_bytes_index keeps track of the byte index of the whole message, not per block 
            // Since one block only equals to 1088/8 = 136 bytes, its not enough for PK to be absorbed

            // Base byte from message if within length, else 0
            // msg_len_bytes = 256/8 = 32 or 9472/8 = 1184
            if (total_bytes_index < msg_len_bytes) begin
                // absorb byte by byte from input msg
                absorb_byte = get_msg_byte(total_bytes_index); // call function to get python order
                // eg : first byte (rightmost, byte index 0) is now at leftmost position (matches python)
                // the function returns the leftmost byte IF total_bytes_index = 0
                // so that the leftmost byte gets absorbed FIRST like in python
                // it is absorbed at the end of the always loop
            end else begin
                absorb_byte = 8'h00; 
            end

            // Domain seperation 
            // Apply SHA3 suffix (0x06) exactly at byte position msg_len_bytes (after the msg)
            // Do that after absorbing the whole message
            
            if (total_bytes_index == msg_len_bytes) begin // if its at byte 32 or 1184 (finished absorbing)
                absorb_byte = absorb_byte ^ SHA3_SUFFIX; // xor 0x06 into that byte
            end

            // Padding
            // (standard: last byte OR= 0x80)
            // if its the LAST BYTE of the LAST BLOCK, pad 1 at the end
            if ((absorb_idx == last_block) && (j == RATE_BYTES-1)) begin
                absorb_byte = absorb_byte | 8'h80;
            end

            // Place byte into rate_block, byte 0 -> bits [7:0]
            // leftmost byte gets absorbed first!
            rate_block[8*j +: 8] = absorb_byte; // do this until finish absorbing (after its at 1088/8 byte )
        end
    end 

    // Keccak state + permutation
    reg  [1599:0] state_reg;
    reg           perm_enable;

    wire [1599:0] perm_out;
    wire          perm_valid;

    permutation u_perm (
        .clk       (clk),
        .enable    (perm_enable),
        .rst       (rst),
        .in        (state_reg),
        .state_out (perm_out),
        .valid     (perm_valid)
    );

    // FSM. Only squeezes once because it only produces 256 bits output
    localparam PH_IDLE      = 3'd0;
    localparam PH_ABSORB    = 3'd1;
    localparam PH_PERMUTE   = 3'd2;
    localparam PH_RESET_PERMUTE = 3'd3;
    localparam PH_SQUEEZE   = 3'd4;
    localparam PH_DONE      = 3'd5;

    reg [2:0] phase; // 0 = idle, 1 = absorb, 2 = permute, 3 = reset_permute, 4 = squeeze, 5 = done

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase         <= PH_IDLE;
            state_reg     <= 1600'b0;
            absorb_idx    <= 8'd0;
            output_string <= 256'b0;
            done          <= 1'b0;
            perm_enable   <= 1'b0;
        end else begin
            // default
            perm_enable <= 1'b0;

            case (phase)
                PH_IDLE: begin
                    done <= 1'b0;
                    if (enable) begin
                        state_reg     <= 1600'b0;
                        absorb_idx    <= 8'd0; //absorbed BLOCK index is initialized here
                        output_string <= 256'b0; // for sha3-256
                        phase         <= PH_ABSORB;
                    end
                end

                // XOR "current" rate_block into state_reg, capacity untouched
                PH_ABSORB: begin
                    // rate block = 1088. capacity bits = 512
                    state_reg[0 +: R] <= state_reg[0 +: R] ^ rate_block; // starting at bit 0 to R (because of the suffix)
                    phase             <= PH_PERMUTE;
                end

                // Run permutation once per absorbed block
                PH_PERMUTE: begin
                    perm_enable <= 1'b1;

                    if (perm_valid) begin
                        state_reg    <= perm_out;

                        if (absorb_idx == last_block) begin
                            phase <= PH_SQUEEZE; // permute one last time 
                        end else begin
                            absorb_idx <= absorb_idx + 1'b1;
                            phase      <= PH_RESET_PERMUTE; // absorb again if there are more than 1 block
                        end
                    end
                end
                PH_RESET_PERMUTE : begin // turn off perm_enable for one cycle
                    perm_enable <= 1'b0;
                    phase <= PH_ABSORB;
                end
                // SHA3-256: output is only 256 bits, so just take them and finish
                PH_SQUEEZE: begin
                    output_string <= state_reg[255:0];
                    phase         <= PH_DONE;
                end

                PH_DONE: begin
                    done <= 1'b1;
                    // output is ready
                end

                default: phase <= PH_IDLE;
            endcase
        end
    end
endmodule
