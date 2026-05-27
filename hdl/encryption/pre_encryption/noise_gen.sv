// == NOISE GENERATOR MODULE == //
/* Uses SHAKE256 to generate random stream from seed (coin) and nonce
and use cbd to generate noise polynomials*/
/* generate e1, e2, r
// poly count 0-2 =  r
// poly count 3-5 = e1
// poly count 6 = e2 */
import params_pkg::*;
module noise_gen (
    input clk,
    input rst,
    input enable,
    input [255:0] coin,
    input  logic hash_valid,
    input  logic [5375:0] hash_message_out,
    output reg noise_done,
    output logic signed [KYBER_POLY_WIDTH-1:0] r[0:KYBER_K-1][0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1:0] e1[0:KYBER_K-1][0:KYBER_N-1],
    output logic signed [KYBER_POLY_WIDTH-1:0] e2[0:KYBER_N-1],

    // HASH CONTROLS OUTPUTS (for shake256)
    output logic hash_start,
    output logic [1:0]  hash_mode,
    output logic [15:0] hash_input_length,
    output logic [15:0] hash_output_length,
    output logic [9471:0] hash_message_in
);
  // -- Noise gen -- //
  logic [4095:0] noise_poly_out;  // 256 coeffs, each coeff is 16 bits. 128 bytes per poly
  reg [2:0] noise_poly_index;  // 0-2
  reg noise_poly_valid;  // valid if poly is ready
  reg [1023:0] noise_stream;  // from shake
  reg [7:0] nonce;  // increment by one every time the poly is produced. 
  // nonce is used to track poly index as well (0-6)
  reg shake_enable;
  reg cbd_enable;
  wire shake_done;
  wire cbd_done;
  
  logic [263:0] shake256_input; 
  logic [263:0] in_updated;

  assign shake256_input = {nonce, coin}; // ASSIGN SHAKE256 INPUT! nonce changes once every poly gets produced until all 7 polys are produced
  /*genvar b;
  generate
    for (b = 0; b < 33; b = b + 1) begin : REORDER
      assign in_updated[b*8 +: 8] = shake256_input[263 - 8*b -: 8];
    end
  endgenerate*/
  /*
  shake256 shake256_coin (
      .clk(clk),
      .enable(shake_enable),
      .rst(rst),
      .in(shake256_input),
      .input_len(256),
      //.nonce(nonce),  // to make the output different even if using the same seed
      .output_len(14'd1024),  // output length 1024 bits
      .output_string(noise_stream),
      .done(shake_done)
  );*/
  localparam logic [15:0]  NOISE_OUTPUT_LENGTH_BITS = 16'd1024;
 /* hash_controller shake256_coin (
      .clk(clk),
      .rst(rst),
      .enable(shake_enable),
      .hash_mode(2'b11), // shake256 mode
      .input_length(16'd264), // 256 bits coin + 8 bits nonce
      .output_length(NOISE_OUTPUT_LENGTH_BITS), // output length in bytes (1024 bits)
      .message_in(shake256_input),
      .message_out(noise_stream),
      .valid(shake_done)
  );*/

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
    if (rst) begin
        state_reg <= IDLE;
        nonce <= 8'd0;
        shake_enable <= 1'b0;
        cbd_enable <= 1'b0;
        noise_done <= 1'b0;
        noise_poly_valid <= 1'b0;

        hash_start <= 1'b0;
        hash_mode <= 2'b00;
        hash_input_length <= 16'd0;
        hash_output_length <= 16'd0;
        hash_message_in <= '0;
        noise_stream <= '0;
        noise_poly_index <= '0;
    end else begin
      // default values
      shake_enable <= 1'b0;
      cbd_enable <= 1'b0;
      noise_poly_valid <= 1'b0;
      hash_start <= 1'b0;

      case (state_reg)
        IDLE: begin
          noise_done <= 1'b0;
          if (enable) begin
            nonce <= 8'd0;
            noise_poly_index <= 0;
            state_reg <= SHAKE_START;
          end
        end
        SHAKE_START: begin
              hash_start <= 1'b1;
              hash_mode <= 2'b11; // SHAKE256
              hash_input_length <= 16'd264;
              hash_output_length <= 16'd1024;
              hash_message_in <= '0;
              hash_message_in[263:0] <= shake256_input;
              state_reg <= WAIT_SHAKE;
        end
        WAIT_SHAKE: begin
          if (hash_valid) begin
            noise_stream <= hash_message_out[1023:0];
            state_reg <= CBD_START;
          end
        end
        CBD_START: begin
          cbd_enable <= 1'b1;
          state_reg  <= RESET_CBD;
        end  // should wait 1 pulse before starting sampling rejection, so rej_done can be resetted
        RESET_CBD: begin
          state_reg <= WAIT_CBD;
        end
        WAIT_CBD: begin
          if (cbd_done) begin
            cbd_enable <= 1'b0;
            noise_poly_valid <= 1'b1;
            state_reg <= POLY_READY;
          end
        end
        POLY_READY: begin
          // if the poly is the last one, finish it
          if (nonce == 6) begin
            state_reg <= DONE;
          end else begin
            if (nonce % 3 == 2) begin
              noise_poly_index <= 1'b0;  // new vector, so reset index
            end else begin
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
      if (nonce <= 2) begin
        for (c = 0; c < 256; c++) begin
          r[noise_poly_index][c] <= $signed(noise_poly_out[c*16+:16]);
        end
      end else if (nonce <= 5) begin
        for (c = 0; c < 256; c++) begin
          e1[noise_poly_index][c] <= $signed(noise_poly_out[c*16+:16]);
        end
      end else begin
        for (c = 0; c < 256; c++) begin
          e2[c] <= $signed(noise_poly_out[c*16+:16]);
        end
      end
    end
  end
endmodule
