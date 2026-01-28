`timescale 1ns / 1ps
`define DELAY 3
// for noise, gen e1,e2,r in kyber768
// e1, r = output poly 3 times (1024 bits each)
// e2 = output poly 1 time
// for public matrix, gen A transpose (9 polys)
// run once, collect 7 polys?
module noise_gen_tb;
  reg clk;
  reg enable;
  reg rst;
  reg [255:0] coin;
  reg noise_done;
  //// output
  wire [15:0] r [0:2][0:255];
  wire [15:0] e1 [0:2][0:255];
  wire [15:0] e2 [0:255];
  wire [4095:0] noise_poly_out;

  reg [15:0] coeff;

  noise_gen noise_gen_uut (
        .clk(clk),
        .enable(enable),
        .rst(rst),
        .coin(coin),
        .noise_done(noise_done),
        //.noise_poly_out(noise_poly_out),
        .r(r),
        .e1(e1),
        .e2(e2)
  );

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, noise_gen_tb);
    //$monitor(" phase:%d\n enable: %h\n nonce:%d\n state_reg: %h\n bit_squeezed :%d\n output len:%d\n output string:%h\n done:%d\n", noise_gen_uut.shake256_coin.phase, noise_gen_uut.shake256_coin.enable, noise_gen_uut.shake256_coin.nonce, noise_gen_uut.shake256_coin.state_reg, noise_gen_uut.shake256_coin.bits_squeezed, noise_gen_uut.shake256_coin.output_len, noise_gen_uut.shake256_coin.output_string, noise_gen_uut.shake_done);
    //$monitor("index: %d\n cbd enable: %d\n, noise poly out:%h\n cbd done:%h\n noise poly valid:%d\n ",noise_gen_uut.noise_poly_index,noise_gen_uut.cbd_enable, noise_gen_uut.noise_poly_out,noise_gen_uut.cbd_done, noise_gen_uut.noise_poly_valid);
    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end
integer i,j,k;
// for printing public matrix
integer round = 0;

initial begin
    // -- INPUT -- //
    rst = 1;
    coin = 256'hf8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598;
    enable = 0;

    // Release reset to start loading state_reg, done, etc
    #(`DELAY) rst = 0;
    #(`DELAY) enable = 1;

    //wait (noise_done == 1'b1);
    wait (noise_done == 1'b1);

    #(`DELAY * 10);

    // -- PRINT OUTPUT POLYS -- //
    for (j=0; j<3; j++) begin
        $display("=== r %0d ===", j);
        for (i = 0; i < 256; i++) begin
            // pack 16 unpacked bits into a packed vector
            coeff = noise_gen_uut.r[j][i];
            $write("%0d ", coeff);
            if ((i % 16) == 15) $write("\n");
        end
        $write("\n");
    end

    for (k=0; k<3; k++) begin
        $display("=== e1 %0d ===", k);
        for (i = 0; i < 256; i++) begin
            // pack 16 unpacked bits into a packed vector
            coeff = noise_gen_uut.e1[k][i];
            $write("%0d ", coeff);
            if ((i % 16) == 15) $write("\n");
        end
        $write("\n");
    end


    $display("=== e2 ===");
    for (i = 0; i < 256; i++) begin
        // pack 16 unpacked bits into a packed vector
        coeff = noise_gen_uut.e2[i];
        $write("%0d ", coeff);
        if ((i % 16) == 15) $write("\n");
    end
    $write("\n");

 end
endmodule

