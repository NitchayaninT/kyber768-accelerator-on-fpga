`timescale 1ns / 1ps
`define DELAY 3
// for noise, gen e1,e2,r in kyber768
// e1, r = output poly 3 times (1024 bits each)
// e2 = output poly 1 time
// run once, collect 7 polys?
module hash_top_tb;
  reg clk;
  reg enable;
  reg rst;
  reg [255:0] in; // coins or seeds
  reg [3:0] domain;
  reg [13:0] output_len;
  // wire [5375:0] A;
  wire [1023:0] poly_out;
  wire done;
  integer i;
  integer a, b, exp;
  integer got;

  hash_top hash_top_uut (
        .clk(clk),
        .enable(enable),
        .rst(rst),
        .coins(in),
        .done(done),
        .poly_out(poly_out)
  );
   task print_state_bytes(input [1023:0] S);
    integer b;
    localparam integer NUM_BYTES = 1024 / 8;  // 128
    reg [1023:0] python_order;
    begin
        // reverse bytes
        for (b = 0; b < NUM_BYTES; b = b + 1) begin
            // python order 0 print shake's last byte (right most), just map reverse order
            // this is for better displaying that left most is LSB
            // now SHAKE also prints from actual LSB to MSB like in python
            python_order[8*b +: 8] = S[8*(NUM_BYTES-1-b) +: 8];
        end
        // print as hex
        $display("python_order = %h", python_order);
    end
endtask

    /*logic [1023:0] noise_polys [0:6]; //store 7 output polys

    always_ff @(posedge clk) begin
        if (rst) begin
            // optional clear
        end else if (poly_valid) begin
            noise_polys[poly_idx] <= poly_out;
        end
    end

    noise_polys[0] = 
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, hash_top_tb);
        $monitor("phase:%d\n done:%h\n poly_out:%h\n ", hash_top_uut.shake128_module.phase, done, poly_out);
        clk = 0;
        forever #(`DELAY / 2) clk = ~clk;
    end

    initial begin
        // -- INPUT -- //
        rst = 1;
        in  = 256'hf8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598;
        enable = 0;
        #(`DELAY*2);
        rst = 0;
        #(`DELAY);
        enable = 1;
        #(`DELAY*500);
        enable = 0;
        #(`DELAY*20);
    end*/
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, hash_top_tb);
    //$display("time  phase  en  round  valid  bits_squeezed");
    //$monitor("%4t  %0d    %b   %2d    %b     %0d",
           ///$time, sponge_const_uut.phase, sponge_const_uut.perm_enable, sponge_const_uut.u_perm.round, sponge_const_uut.perm_valid, sponge_const_uut.bits_squeezed);
    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end

 initial begin
    // -- INPUT -- //
    rst = 1;
    in  = 256'hf8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598;
    enable = 0;

    // Release reset to start loading state_reg, done, etc
    #(`DELAY) rst = 0;
    #(`DELAY) enable = 1;

    @(posedge hash_top_uut.shake_done);
    #(`DELAY * 5);

    $display("\n\noutput from SHAKE : %h\n",hash_top_uut.shake_stream[1023:0]);
    print_state_bytes(hash_top_uut.shake_stream[1023:0]);
    $display("\n\ndone : %b\n output string = %h\n", done, poly_out);
    print_state_bytes(poly_out);

    $display("CBD coeffs (0..255):");
        for (i = 0; i < 256; i=i+1) begin
        $write("%0d ", $signed(poly_out[i*4 +: 4]));
        if ((i%16)==15) $write("\n");
    end
    $finish;
 end
endmodule