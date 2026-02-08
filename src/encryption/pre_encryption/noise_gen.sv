// == NOISE GENERATOR MODULE == //
/* Uses SHAKE256 to generate random stream from seed (coin) and nonce
and use cbd to generate noise polynomials*/
/* generate e1, e2, r
// poly count 0-2 =  r
// poly count 3-5 = e1
// poly count 6 = e2 */
`timescale 1ns / 1ps
module noise_gen(
    input clk,
    input rst,
    input enable,
    input [255:0] coin,
    output reg noise_done,
    //output reg [4095:0] noise_poly_out,
    output reg [15:0] r [0:2][0:255],
    output reg [15:0] e1 [0:2][0:255],
    output reg [15:0] e2 [0:255]
);
// -- Noise gen -- //
    wire [4095:0] noise_poly_out; // 256 coeffs, each coeff is 16 bits. 128 bytes per poly
    reg [2:0] noise_poly_index; // 0-2
    reg noise_poly_valid; // valid if poly is ready
    wire [1023:0] noise_stream; // from shake
    reg [7:0] nonce; // increment by one every time the poly is produced. 
    // nonce is used to track poly index as well (0-6)
    reg shake_enable;
    reg cbd_enable;
    wire shake_done;
    wire cbd_done;

    shake256 shake256_coin (
        .clk(clk),
        .enable(shake_enable),
        .rst(rst),
        .in(coin),
        .nonce(nonce), // to make the output different even if using the same seed
        .output_len(14'd1024), // output length 1024 bits
        .output_string(noise_stream),
        .done(shake_done)
    );

    cbd cbd_module (
        .clk(clk),
        .rst(rst),
        .enable(cbd_enable),
        .noise(noise_stream),
        .done(cbd_done),
        .poly_out(noise_poly_out)
    );

    // FSM states
    localparam IDLE = 3'd0;
    localparam SHAKE_START = 3'd1;
    localparam WAIT_SHAKE = 3'd2;
    localparam CBD_START = 3'd3;
    localparam RESET_CBD = 3'd4;
    localparam WAIT_CBD = 3'd5;
    localparam POLY_READY = 3'd6;
    localparam DONE = 3'd7;

    reg [2:0] state_reg;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state_reg <= IDLE;
            nonce <= 8'd0;
            shake_enable <= 1'b0;
            cbd_enable <= 1'b0;
            noise_done <= 1'b0;
            noise_poly_valid <= 1'b0;
        end else begin
            // default values
            shake_enable <= 1'b0;
            cbd_enable <= 1'b0;
            noise_poly_valid <= 1'b0;

            case (state_reg)
                IDLE: begin
                    noise_done <= 1'b0;
                    if(enable) begin
                        nonce <= 8'd0;
                        noise_poly_index <= 0;
                        state_reg <= SHAKE_START;
                    end
                end
                SHAKE_START: begin
                    shake_enable <= 1'b1;
                    state_reg <= WAIT_SHAKE;
                end
                WAIT_SHAKE: begin
                    if(shake_done) begin
                        shake_enable <= 1'b0;
                        state_reg <= CBD_START;
                    end
                end
                CBD_START: begin
                    cbd_enable <= 1'b1;
                    state_reg <= RESET_CBD;
                end // should wait 1 pulse before starting sampling rejection, so rej_done can be resetted
                RESET_CBD: begin
                    state_reg <= WAIT_CBD;
                end
                WAIT_CBD: begin
                    if(cbd_done) begin
                        cbd_enable <= 1'b0;
                        noise_poly_valid <= 1'b1;
                        state_reg <= POLY_READY;
                    end
                end
                POLY_READY: begin
                    // if the poly is the last one, finish it
                    if(nonce == 6) begin
                        state_reg <= DONE;
                    end else begin
                        if (nonce % 3 == 2) begin
                            noise_poly_index <= 1'b0; // new vector, so reset index
                        end
                        else begin
                            noise_poly_index <= noise_poly_index + 1;
                        end
                        nonce <= nonce + 1;
                        state_reg <= SHAKE_START;
                        shake_enable <= 1'b1;
                    end
                end
                DONE: begin
                    noise_done <= 1'b1;
                end
            endcase
        end
    end
integer c;
always_ff @(posedge clk) begin
  if (noise_poly_valid) begin
    if(nonce <= 2) begin
        for (c = 0; c < 256; c++) begin
            r[noise_poly_index][c] <= noise_poly_out[c*16 +: 16];
        end
    end
    else if (nonce <= 5) begin
        for (c = 0; c < 256; c++) begin
            e1[noise_poly_index][c] <= noise_poly_out[c*16 +: 16];
        end
    end
    else begin
        for (c = 0; c < 256; c++) begin
            e2[c] <= noise_poly_out[c*16 +: 16];
        end
    end
  end
end
endmodule