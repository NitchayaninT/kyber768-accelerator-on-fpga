// Reduce top, which takes in u and v from Addition
// this control module will feed u and v into the reduce module one at a time, and store the reduced output for post-encryption
`timescale 1ns / 1ps
`include "params.vh"
module reduce_top (
    input clk,
    input rst,
    input enable,
    input  [15:0] u [0:2][0:255], // u and v from post-encryption
    input  [15:0] v [0:255],
    output reg [11:0] out_u [0:2][0:255], // reduced u for post-enc
    output reg [11:0] out_v [0:255], // reduced v for post-enc
    output reg reduce_done
);
    integer i;
    logic [15:0] in_poly  [0:255];
    wire  [11:0] ready_out  [0:255];  
    wire  reduce_done_core;
    wire  busy;

  
typedef enum logic [2:0] {IDLE, LOAD, START, WAIT, STORE, NEXT, DONE} st_t;
st_t st;

logic [1:0] poly_index; // 0-3
logic [7:0] idx; // 0-255
logic reduce_start;

 // Reduce module
    reduce reduce_uut(
    .clk(clk), 
    .rst(rst),
    .enable(reduce_start),
    .in_poly(in_poly),
    .busy(busy),
    .reduce_done(reduce_done_core),
    .out_poly(ready_out)
);

always_ff @(posedge clk) begin
  if (rst) begin
    st <= IDLE;
    poly_index <= 0;
    idx <= 0;
    reduce_start <= 0;
    reduce_done <= 0;
  end else begin
    reduce_start <= 0;   
    reduce_done  <= 0;

    case (st)
      IDLE: begin
        if (enable) begin
          poly_index <= 0;
          idx <= 0;
          st <= LOAD;
        end
      end

      // load 1 coeff per cycle
      LOAD: begin
        if (poly_index < 3)
          in_poly[idx] <= u[poly_index][idx];
        else
          in_poly[idx] <= v[idx];

        if (idx == 8'd255) begin
          idx <= 0;
          st <= START;
        end else idx <= idx + 1;
      end

      START: begin
        reduce_start <= 1'b1; 
        st <= WAIT;
      end

      WAIT: begin
        if (reduce_done_core) begin
          idx <= 0;
          st <= STORE;
        end
      end

      // store 1 coeff per cycle
      STORE: begin
        if (poly_index < 3)
          out_u[poly_index][idx] <= ready_out[idx]; // from reduced output
        else
          out_v[idx] <= ready_out[idx];

        if (idx == 8'd255) begin
          idx <= 0;
          st <= NEXT;
        end else idx <= idx + 1;
      end

      NEXT: begin
        if (poly_index == 2'd3) st <= DONE;
        else begin
          poly_index <= poly_index + 1;
          st <= LOAD;
        end
      end

      DONE: begin
        reduce_done <= 1'b1;
        if (!enable) st <= IDLE;
      end
    endcase
  end
end

endmodule