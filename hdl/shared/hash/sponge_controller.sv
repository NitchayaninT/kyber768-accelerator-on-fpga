/* ## sponge_controller (Control absorb/pad/squeeze)= handles SHA3/SHAKE behavior
replaces the old seperated hashes into "sponge controller"
- rate selection
- padding/domain suffix
- absorb
- squeeze
- output length */

module sponge_controller #(
    parameter int MAX_INPUT_BITS  = 9472, // (sha3-256 pk input)
    parameter int MAX_OUTPUT_BITS = 5376 // (shake128 max output for public matrix)
)(
    input  logic clk,
    input  logic rst,

    input  logic start,
    output logic busy,

    input  logic [1:0] hash_mode, // 00 sha3-256, 01 sha3-512, 10 shake128, 11 shake256
    input  logic [15:0] input_len_bytes,
    input  logic [15:0] output_len_bytes, // for shake only

    input  logic [MAX_INPUT_BITS-1:0]  message_in,
    output logic [MAX_OUTPUT_BITS-1:0] message_out,

    output logic valid
);
    // FSM. Only squeezes once because it only produces 256 bits output
    typedef enum logic [3:0] {
        PH_IDLE,
        PH_ABSORB,
        PH_PERMUTE,
        PH_RESET_PERMUTE,
        PH_SQUEEZE,
        PH_RESET_SQUEEZE_PERMUTE, // wait state between squeezing blocks so perm_valid has time to go low before starting the next permutation
        PH_CLEAR,
        PH_DONE
    } phase_t;

    phase_t phase;

    localparam int MAX_RATE_BYTES = 168; // max rate in bytes among the 4 modes (shake128 with 1344 bits)
    
    // internal signals
    logic [15:0] rate_bytes;
    logic [7:0]  domain_suffix;
    logic [15:0] real_output_len;

    logic [1599:0] state_reg;
    logic [MAX_RATE_BYTES*8-1:0] rate_block;

    logic [15:0] absorbed_bytes; // byte offset of the current absorb block = absorb_idx * rate_bytes
    logic        is_last_block;  // true when the current block covers all remaining input bytes

    logic perm_enable;
    logic [1599:0] perm_out;
    logic perm_valid;

    logic [15:0] bytes_squeezed; // keep track of bytes squeezed so far

    permutation u_perm (
        .clk(clk),
        .enable(perm_enable),
        .rst(rst),
        .in(state_reg),
        .state_out(perm_out),
        .valid(perm_valid)
    );

always_comb begin
    case (hash_mode)
        2'b00: begin // SHA3-256
            rate_bytes      = 16'd136; // 1088 bits
            domain_suffix   = 8'h06;
            real_output_len = 16'd32;  // 256 bits
        end

        2'b01: begin // SHA3-512
            rate_bytes      = 16'd72;  // 576 bits
            domain_suffix   = 8'h06;
            real_output_len = 16'd64;  // 512 bits
        end

        2'b10: begin // SHAKE128
            rate_bytes      = 16'd168; // 1344 bits
            domain_suffix   = 8'h1F;
            real_output_len = output_len_bytes;
        end

        2'b11: begin // SHAKE256
            rate_bytes      = 16'd136; // 1088 bits
            domain_suffix   = 8'h1F;
            real_output_len = output_len_bytes;
        end
    endcase
end

// current block covers all input when absorbed_bytes + rate_bytes exceeds input length
// (strict > required: when absorbed_bytes == input_len_bytes the padding block still belongs to the NEXT block)
assign is_last_block = (absorbed_bytes + rate_bytes > input_len_bytes);

// ABSORBPTION
always_comb begin
    rate_block = '0;

    for (int j = 0; j < MAX_RATE_BYTES; j = j + 1) begin
        logic [15:0] total_bytes_index;
        logic [7:0]  absorb_byte;

        total_bytes_index = absorbed_bytes + j;
        absorb_byte       = 8'h00;

        if (j < rate_bytes) begin
            if (total_bytes_index < input_len_bytes) begin
                absorb_byte = message_in[8*total_bytes_index +: 8];
            end

            // domain suffix 
            if (total_bytes_index == input_len_bytes) begin
                absorb_byte = absorb_byte ^ domain_suffix;
            end

            if (is_last_block && (j == rate_bytes - 1)) begin
                absorb_byte = absorb_byte | 8'h80;
            end

            rate_block[8*j +: 8] = absorb_byte;
        end
    end
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        phase       <= PH_IDLE;
        state_reg      <= '0;
        absorbed_bytes <= '0;
        message_out    <= '0;
        valid          <= 1'b0;
        busy           <= 1'b0;
        perm_enable    <= 1'b0;
        bytes_squeezed <= '0;
    end else begin
        perm_enable <= 1'b0;
        valid       <= 1'b0;

        case (phase)
            PH_IDLE: begin
                busy <= 1'b0;

                if (start) begin
                    busy           <= 1'b1;
                    state_reg      <= '0;
                    absorbed_bytes <= '0;
                    message_out    <= '0;
                    phase          <= PH_ABSORB;
                end
            end

            PH_ABSORB: begin
                busy <= 1'b1;

                for (int k = 0; k < MAX_RATE_BYTES; k = k + 1) begin
                    if (k < rate_bytes) begin
                        state_reg[8*k +: 8] <= state_reg[8*k +: 8] ^ rate_block[8*k +: 8];
                    end
                end

                phase <= PH_PERMUTE;
            end

            PH_PERMUTE: begin
                busy        <= 1'b1;
                perm_enable <= 1'b1;

                if (perm_valid) begin
                    state_reg <= perm_out;

                    if (is_last_block) begin
                        phase <= PH_SQUEEZE;
                    end else begin
                        absorbed_bytes <= absorbed_bytes + rate_bytes;
                        phase          <= PH_RESET_PERMUTE;
                    end
                end
            end

            PH_RESET_PERMUTE: begin
                busy  <= 1'b1;
                phase <= PH_ABSORB;
            end

            PH_SQUEEZE: begin
                busy <= 1'b1;
                for (int k = 0; k < MAX_RATE_BYTES; k = k + 1) begin
                    if ((k < rate_bytes) && ((bytes_squeezed + k) < real_output_len)) begin
                        message_out[8*(bytes_squeezed + k) +: 8] <= state_reg[8*k +: 8];
                    end
                end

                if ((bytes_squeezed + rate_bytes) >= real_output_len) begin
                    bytes_squeezed <= '0;
                    phase <= PH_DONE;
                end else begin
                    bytes_squeezed <= bytes_squeezed + rate_bytes;
                    phase <= PH_RESET_SQUEEZE_PERMUTE;
                end
            end
            PH_RESET_SQUEEZE_PERMUTE: begin
                // wait 1 more cycle for perm_enable to reset
                busy <= 1'b1;
                phase <= PH_PERMUTE;
            end
            // 4. Done
            PH_DONE: begin
                valid <= 1'b1;
                busy  <= 1'b0;
                phase <= PH_CLEAR;
            end

            PH_CLEAR: begin
                valid <= 1'b0;
                busy  <= 1'b0;
                phase <= PH_IDLE;
            end
        endcase
    end
end

endmodule