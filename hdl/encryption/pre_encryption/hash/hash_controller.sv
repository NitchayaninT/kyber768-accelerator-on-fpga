/* receives hash requests from encryption top
*- Inputs*
    - flag for choosing hash
    - input length
    - output length (for SHAKE), if for SHA, then just input actual output length
    - message
*- Logic*
    - if sha3-256 (mode 00)
        - rate = 1088
        - domain suffix = 0x06
        - output length = 256
    - if sha3-512 (mode 01)
        - rate = 576
        - domain suffix = 0x06
        - output length = 512
    - if shake128 (mode 10)
        - rate = 1344
        - domain suffix = 0x1F
        - output length = variable
    - if shake256 (mode 11)
        - rate = 1088
        - domain suffix = 0x1F
        - output length = variable
*- Outputs*
    - message
    - flag 
*/
module hash_controller (
    input  logic clk,
    input  logic rst,
    input  logic enable,
    input  logic [1:0] hash_mode, // 00 sha3-256, 01 sha3-512, 10 shake128, 11 shake256
    input  logic [15:0] input_length, // integer (in bits)
    input  logic [15:0] output_length, // bytes (for SHAKE)
    input  logic [9471:0] message_in,
    output logic [5375:0] message_out,
    output logic valid
);

    // enable signals for hash modules
    logic [5375:0] sponge_out;
    logic sponge_valid;

sponge_controller sponge_ctrl (
    .clk(clk),
    .rst(rst),
    .start(enable),
    .hash_mode(hash_mode),
    .input_len_bytes(input_length/8),
    .output_len_bytes(output_length/8),
    .message_in(message_in),
    .message_out(sponge_out),
    .valid(sponge_valid)
);

    always_comb begin
        message_out = '0;
        valid = sponge_valid;

        case (hash_mode)
            2'b00: message_out[255:0]  = sponge_out[255:0];
            2'b01: message_out[511:0]  = sponge_out[511:0];
            2'b10: message_out          = sponge_out;
            2'b11: message_out[1023:0] = sponge_out[1023:0];
            default: begin
                message_out = '0;
                valid = 1'b0;
            end
        endcase
    end
    initial begin
    $display("BOUND HASH_CONTROLLER: %m output_length=%b", output_length);
end

endmodule