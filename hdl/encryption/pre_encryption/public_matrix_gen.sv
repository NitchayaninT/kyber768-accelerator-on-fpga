// HASH top module
// Seed 256 bits -> SHAKE128 -> 5376 bits public matrix A transpose -> Reject sampling -> 9 polynomials
import params_pkg::*;

module public_matrix_gen(
    input clk,
    input rst,
    input enable,
    input [255:0] seed,

    input logic hash_valid,
    input logic [5375:0] hash_message_out,

    output reg public_matrix_done,
    output reg [3:0] public_matrix_poly_index,
    output reg public_matrix_poly_valid,
    output reg signed [15:0] A [0:8][0:255],

    output logic hash_start,
    output logic [1:0]  hash_mode,
    output logic [15:0] hash_input_length,
    output logic hash_matrix_gen,
    // BRAM write port for message bytes
    output logic        hash_msg_wr_en,
    output logic [10:0] hash_msg_wr_addr,
    output logic [ 7:0] hash_msg_wr_data
);

    logic [5375:0] public_matrix_stream;
    wire  [4095:0] public_matrix_poly_out;
    reg [7:0] index_i, index_j;
    reg rej_enable;
    wire rej_done;

    logic [271:0] shake128_input;
    assign shake128_input = {seed, index_i, index_j};

    // byte-reverse for correct endianness into hash_controller
    wire [271:0] in_updated;
    genvar b;
    generate
        for (b = 0; b < 34; b = b + 1) begin : REORDER
            assign in_updated[b*8 +: 8] = shake128_input[271-8*b -:8];
        end
    endgenerate

    reject_sampling reject_sampling_module (
        .clk(clk),
        .rst(rst),
        .enable(rej_enable),
        .byte_stream(public_matrix_stream),
        .done(rej_done),
        .public_matrix_poly(public_matrix_poly_out)
    );

    wire [3:0] pm_index_calc = (index_i * 3) + index_j;

    localparam IDLE       = 3'd0;
    localparam SHAKE_LOAD = 3'd1;  // write 34 bytes to hash_controller BRAM
    localparam SHAKE_START = 3'd2;
    localparam WAIT_SHAKE = 3'd3;
    localparam REJ_START  = 3'd4;
    localparam RESET_REJ  = 3'd5;
    localparam WAIT_REJ   = 3'd6;
    localparam POLY_READY = 3'd7;
    localparam DONE       = 4'd8;

    reg [3:0] state_reg;
    reg [5:0] load_cnt;   // counts 0..33 (34 bytes)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg              <= IDLE;
            index_i                <= 8'd0;
            index_j                <= 8'd0;
            load_cnt               <= '0;
            hash_start             <= 1'b0;
            hash_mode              <= 2'b00;
            hash_input_length      <= 16'd0;
            hash_matrix_gen        <= 1'b0;
            hash_msg_wr_en         <= 1'b0;
            hash_msg_wr_addr       <= '0;
            hash_msg_wr_data       <= '0;
            public_matrix_stream   <= '0;
            rej_enable             <= 1'b0;
            public_matrix_done     <= 1'b0;
            public_matrix_poly_valid <= 1'b0;
            public_matrix_poly_index <= 4'd0;
        end else begin
            hash_start               <= 1'b0;
            hash_msg_wr_en           <= 1'b0;
            rej_enable               <= 1'b0;
            public_matrix_poly_valid <= 1'b0;

            case (state_reg)
                IDLE: begin
                    public_matrix_done <= 1'b0;
                    if (enable) begin
                        index_i   <= 8'd0;
                        index_j   <= 8'd0;
                        load_cnt  <= '0;
                        state_reg <= SHAKE_LOAD;
                    end
                end

                SHAKE_LOAD: begin
                    // Write one byte per cycle: in_updated[load_cnt*8+:8]
                    hash_msg_wr_en   <= 1'b1;
                    hash_msg_wr_addr <= {5'd0, load_cnt};
                    hash_msg_wr_data <= in_updated[{load_cnt, 3'b000} +: 8];
                    if (load_cnt == 6'd33) begin
                        load_cnt  <= '0;
                        state_reg <= SHAKE_START;
                    end else begin
                        load_cnt <= load_cnt + 6'd1;
                    end
                end

                SHAKE_START: begin
                    hash_start        <= 1'b1;
                    hash_mode         <= 2'b10;  // SHAKE128
                    hash_input_length <= 16'd34; // 34 bytes = seed(32) + i(1) + j(1)
                    hash_matrix_gen   <= 1'b1;   // 4-squeeze mode
                    state_reg         <= WAIT_SHAKE;
                end

                WAIT_SHAKE: begin
                    if (hash_valid) begin
                        public_matrix_stream <= hash_message_out[5375:0];
                        state_reg            <= REJ_START;
                    end
                end

                REJ_START: begin
                    rej_enable <= 1'b1;
                    state_reg  <= RESET_REJ;
                end

                RESET_REJ: begin
                    public_matrix_poly_index <= pm_index_calc;
                    state_reg                <= WAIT_REJ;
                end

                WAIT_REJ: begin
                    if (rej_done) begin
                        rej_enable <= 1'b0;
                        state_reg  <= POLY_READY;
                    end
                end

                POLY_READY: begin
                    public_matrix_poly_valid <= 1'b1;
                    if (index_i == 2 && index_j == 2) begin
                        state_reg <= DONE;
                    end else begin
                        if (index_j == 2) begin
                            index_i <= index_i + 1;
                            index_j <= 0;
                        end else begin
                            index_j <= index_j + 1;
                        end
                        load_cnt  <= '0;
                        state_reg <= SHAKE_LOAD;
                    end
                end

                DONE: public_matrix_done <= 1'b1;
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
