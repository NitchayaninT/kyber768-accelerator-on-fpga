// HASH top module
// Workflow
// Seed 256 bits -> SHAKE128 -> 5376 bits public matrix A transpose -> Reject sampling -> 9 polynomials of degree 256 with coeffs in [0,3328]
// Coins 256 bits -> SHAKE128 -> 1024 bits noise -> CBD -> polynomial of degree 256 with coeffs in [-2,2]
// public mat poly index = i*k + j (k=3 in kyber 768)
// noise poly index = just 0 + j

module public_matrix_gen(
    input clk,
    input rst,
    input enable,
    input [255:0] seed,
    // SHAKE CONTROLS INPUTS
    input logic hash_valid,
    input logic [5375:0] hash_message_out,

    // OUTPUTS
    output reg public_matrix_done,
    // output 1 poly at a time
    output reg [3:0] public_matrix_poly_index,
    output reg public_matrix_poly_valid,
    output reg signed [15:0] A [0:8][0:255], // each coef has 16 bits
    // SHAKE CONTROLS OUTPUTS
    output logic hash_start,
    output logic [1:0]  hash_mode,
    output logic [15:0] hash_input_length,
    output logic [15:0] hash_output_length,
    output logic [9471:0] hash_message_in,
    output logic hash_matrix_gen
);

// -- Public Matrix Loop Gen -- //
// Input index i & j along with the seed (specified in NIST203)
// Reason : so that the poly outputs are different, even tho they're using the same seed
    logic [5375:0] public_matrix_stream;
    wire  [4095:0] public_matrix_poly_out;
    reg [7:0] index_i, index_j;
    // reg shake_pm_enable; // enable calling shake module
    reg rej_enable; // enable calling sampling rejection
    // wire shake_pm_done; // done flag for public matrix's shake
    wire rej_done; // done flag for samp rejection
    // wire [5375:0] public_matrix_stream; // stream after shake.

    // idea for shake128 : input seed + index_i and index_j AT THE SAME TIME
    logic [271:0] shake128_input; 
    assign shake128_input = {seed,index_i,index_j}; // concatenate index and seed together as input for shake128, so that we can generate different stream for different poly index
    
    // reverse outside shake module before feeding into shake
    wire [271:0] msg_bits;
    wire [271:0] in_updated;
    genvar b;
    generate
        for (b = 0; b < 34; b = b + 1) begin : REORDER // so that the left most bits will be read first
            assign msg_bits[b*8 +: 8] = shake128_input[271-8*b -:8];
        end
    endgenerate
    assign in_updated[271:0]   = msg_bits;
    
    localparam logic [15:0]  PM_OUTPUT_LENGTH_BITS = 16'd5376;

    /*hash_controller hash_ctrl (
        .clk          (clk),
        .rst          (rst),
        .enable       (shake_pm_enable),
        .hash_mode    (2'b10), // shake128 mode
        .input_length (16'd272),
        .output_length(PM_OUTPUT_LENGTH_BITS), // output length in bytes (5376 bits)
        .message_in   (in_updated), //271 bits input
        .message_out  (public_matrix_stream),
        .valid        (shake_pm_done)
    );*/
/*
    shake128 shake128_public_matrix (
        .clk(clk),
        .enable(shake_pm_enable),
        .rst(rst),
        .in(in_updated),
        .output_len(PM_OUTPUT_LENGTH_BITS), // output length 5376 bits
        .output_string(public_matrix_stream),
        .done(shake_pm_done)
    );*/

    reject_sampling reject_sampling_module (
        .clk(clk),
        .rst(rst),
        .enable(rej_enable),
        .byte_stream(public_matrix_stream),
        .done(rej_done),
        .public_matrix_poly(public_matrix_poly_out)
    );

    // poly index = i*3 + j
    wire [3:0] pm_index_calc = (index_i * 3) + index_j;

    // FSM states
    localparam IDLE = 3'd0;
    localparam SHAKE_START = 3'd1;
    localparam WAIT_SHAKE = 3'd2;
    localparam REJ_START = 3'd3;
    localparam RESET_REJ = 3'd4;
    localparam WAIT_REJ = 3'd5;
    localparam POLY_READY = 3'd6;
    localparam DONE = 3'd7;

    reg [2:0] state_reg;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state_reg <= IDLE;
            index_i <= 8'd0;
            index_j <= 8'd0;

            hash_start <= 1'b0;
            hash_mode <= 2'b00;
            hash_input_length <= 16'd0;
            hash_output_length <= 16'd0;
            hash_message_in <= '0;
            hash_matrix_gen <= 1'b0;

            public_matrix_stream <= '0;

            rej_enable <= 1'b0;
            public_matrix_done <= 1'b0;
            public_matrix_poly_valid <= 1'b0;
            public_matrix_poly_index <= 4'd0;
        end else begin
            // default values
            //shake_pm_enable <= 1'b0;
            hash_start <= 1'b0;  
            rej_enable <= 1'b0;
            public_matrix_poly_valid <= 1'b0;

            case (state_reg)
                IDLE: begin
                    public_matrix_done <= 1'b0;
                    if(enable) begin
                        index_i <= 8'd0;
                        index_j <= 8'd0;
                        state_reg <= SHAKE_START;
                    end
                end
                SHAKE_START: begin
                      hash_start <= 1'b1;
                      hash_mode <= 2'b10; // SHAKE128
                      hash_input_length <= 16'd34;   // 34 bytes = seed(32) + i(1) + j(1)
                      hash_output_length <= 16'd5376;
                      hash_matrix_gen <= 1'b1;
                      hash_message_in <= '0;
                      hash_message_in[271:0] <= in_updated;
                      state_reg <= WAIT_SHAKE;
                end
                WAIT_SHAKE: begin
                    if(hash_valid) begin
                        public_matrix_stream <= hash_message_out[5375:0];
                        state_reg <= REJ_START;
                    end
                end
                REJ_START: begin
                    rej_enable <= 1'b1;
                    state_reg <= RESET_REJ;
                end // should wait 1 pulse before starting sampling rejection, so rej_done can be resetted
                RESET_REJ: begin
                    public_matrix_poly_index <= pm_index_calc;
                    state_reg <= WAIT_REJ;
                end
                WAIT_REJ: begin
                    if(rej_done) begin
                        //public_matrix_poly_out <= rej_poly;
                        //public_matrix_poly_index <= pm_index_calc;
                        rej_enable <= 1'b0;
                        state_reg <= POLY_READY;
                    end
                end
                POLY_READY: begin
                    public_matrix_poly_valid <= 1'b1;

                    // if this poly is the last one, finish
                    if(index_i == 2 && index_j == 2) begin
                        state_reg <= DONE;
                    end else begin // increment index
                        if(index_j == 2) begin
                            index_i <= index_i+1;
                            index_j <= 0;
                        end else begin
                            index_j <= index_j+1;
                        end
                        state_reg <= SHAKE_START;
                        //shake_pm_enable <= 1'b1;
                    end
                end
                DONE: begin
                    public_matrix_done <= 1'b1;
                end
            endcase
        end
    end
integer c;
always_ff @(posedge clk) begin
  if (public_matrix_poly_valid) begin
    for (c = 0; c < 256; c++) begin
      A[public_matrix_poly_index][c] <= public_matrix_poly_out[c*16 +: 16];
    end
  end
end
endmodule
