
// Default lenght of the input/output is 32 Bytes
module shake128 #(
    parameter int IN_LENGTH  = 32,
    parameter int OUT_LENGTH = 32
) (
    input clk,
    input wire [(IN_LENGTH * 8)-1:0] in,
    output reg [(OUT_LENGTH * 8)-1:0] out,
    output reg valid
);
  reg [(OUT_LENGTH * 8) - 1 : 0] buffer = 0;
  reg [1600-1:0] keccak_state = 0;  // 25 lanes 64 bytes each
  reg [7:0] IO_index = 0;  // index of byte in keccak_state
  reg squeezing = 0;

  reg lane = 0;
  reg offset = 0;

  always @(posedge clk) begin
    // copy input to state
    // the state are structure in lane and we will process each lane one as
    // a time
    integer i;
    for (i = 0; i < 21; i = i + 1) begin
      keccak_state[i*64+:64] = in[i*64+:64];  // only 256 bits input → 4 chunks
    end
    keccak_state[255]               = 1;  // start padding (after last input bit)
    keccak_state[256+:(1344-256-1)] = 0;  // fill remaining rate bits with zeros
    keccak_state[1343]              = 1;  // end of rate
    // capacity already = 0;

  end
endmodule

module shake128_permute (
    input clk,
    input wire [1600 - 1:0] state,
    output reg [1600 - 1 : 0] permuted_state,
    output reg valid
);
  reg [2:0] state = 0;  // there are 5 state in each permutation loop
  reg [4:0] counter = 0;  // permute 24 times
  //for five step of the counter
  always @(posedge clk) begin
    while (counter < 24) begin
      case (state)
        3'b000: begin
        end
        3'b001: begin

        end
        3'b010: begin

        end
        3'b011: begin

        end
        3'b100: begin

        end
        default : valid = 0;
      endcase
    end

  end
endmodule
