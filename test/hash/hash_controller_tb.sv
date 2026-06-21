`timescale 1ns/1ps

/* Compile:
   iverilog -g2012 \
     hdl/params_pkg.sv hdl/enums_pkg.sv \
     hdl/shared/hash/permutation/theta.sv \
     hdl/shared/hash/permutation/rho.sv \
     hdl/shared/hash/permutation/pi.sv \
     hdl/shared/hash/permutation/chi.sv \
     hdl/shared/hash/permutation/iota.sv \
     hdl/shared/hash/permutation.sv \
     hdl/shared/hash/sponge_controller.sv \
     hdl/shared/hash/hash_controller.sv \
     test/hash/hash_controller_tb.sv \
     -o sim.out && vvp sim.out
*/

module hash_controller_tb;

    logic          clk, rst;
    logic          enable;
    logic [1:0]    hash_mode;
    logic          matrix_gen;
    logic [15:0]   input_length;
    logic [15:0]   output_length;
    logic [9471:0] message_in;
    logic [5375:0] message_out;
    logic          valid;

    hash_controller dut (
        .clk         (clk),
        .rst         (rst),
        .enable      (enable),
        .hash_mode   (hash_mode),
        .matrix_gen  (matrix_gen),
        .input_length (input_length),
        .output_length(output_length),
        .message_in  (message_in),
        .message_out (message_out),
        .valid       (valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, hash_controller_tb);
    end


    // wait for valid, timeout after n_max cycles
    // #1 delay after posedge reads valid past the NBA phase (registered output)
    task automatic wait_done;
        integer i;
        i = 0;
        while (!valid) begin
            @(posedge clk); #1;
            i = i + 1;
            if (i > 200000) begin
                $display("TIMEOUT");
                $finish;
            end
        end
    endtask

    // print n_bytes of message_out starting at byte 0 (standard hash byte order)
    task automatic print_bytes;
        input integer n_bytes;
        integer j;
        for (j = 0; j < n_bytes; j = j + 1)
            $write("%h", message_out[8*j +: 8]);
        $write("\n");
    endtask

    // check first 32 bytes against expected 256-bit value (byte 0 at bits [7:0])
    task automatic check256;
        input [255:0] expected;
        input string  label;
        if (message_out[255:0] === expected)
            $display("PASS");
        else begin
            $display("FAIL");
            $write("  got:      "); print_bytes(32);
            $display("  expected: %h", expected);
        end
    endtask

    initial begin
        // reset
        rst = 1'b1; enable = 1'b0;
        hash_mode = 2'b00; matrix_gen = 1'b0;
        input_length = 16'd0; output_length = 16'd0;
        message_in = '0;
        repeat(4) @(posedge clk);
        @(negedge clk); rst = 1'b0;
        repeat(2) @(posedge clk);

        // ------------------------------------------------------------
        // Test 1: SHA3-256 empty string (0 bytes)
        // Expected: a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a
        // 1 block: block[0]^=0x06, block[135]^=0x80
        // ------------------------------------------------------------
        $display("=== Test 1: SHA3-256 empty string ===");
        @(negedge clk);
        hash_mode = 2'b00; matrix_gen = 1'b0;
        input_length = 16'd0; output_length = 16'd32;
        message_in = '0;
        enable = 1'b1;
        wait_done();
        @(negedge clk); enable = 1'b0;
        $write("got:      "); print_bytes(32);
        $display("expected: a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a");
        // comparison value: byte 31 at MSB → 4a43...ffa7
        check256(256'h4a43f8804b0ad882fa493be44dff80f562d661a05647c15166d71ebff8c6ffa7, "SHA3-256 empty");
        $display("");
        repeat(4) @(posedge clk);

        // ------------------------------------------------------------
        // Test 2: SHA3-256 "abc" (3 bytes: 0x61 0x62 0x63)
        // Expected: 3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532
        // ------------------------------------------------------------
        $display("=== Test 2: SHA3-256 'abc' (3 bytes) ===");
        @(negedge clk);
        hash_mode = 2'b00; matrix_gen = 1'b0;
        input_length = 16'd3; output_length = 16'd32;
        message_in = '0;
        message_in[7:0]   = 8'h61;  // 'a'
        message_in[15:8]  = 8'h62;  // 'b'
        message_in[23:16] = 8'h63;  // 'c'
        enable = 1'b1;
        wait_done();
        @(negedge clk); enable = 1'b0;
        $write("got:      "); print_bytes(32);
        $display("expected: 3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532");
        check256(256'h3215431145e2bf465b529d3e6e085f85bd90d36b2d175c04b225e24fa75d983a, "SHA3-256 abc");
        $display("");
        repeat(4) @(posedge clk);

        // ------------------------------------------------------------
        // Test 3: SHAKE128 empty string, no matrix_gen (1 squeeze = 168B)
        // Expected first 32B: 7f9c2ba4e88f827d616045507605853ed73b8093f6efbc88eb1a6eacfa66ef26
        // ------------------------------------------------------------
        $display("=== Test 3: SHAKE128 empty string (no matrix_gen) ===");
        @(negedge clk);
        hash_mode = 2'b10; matrix_gen = 1'b0;
        input_length = 16'd0; output_length = 16'd168;
        message_in = '0;
        enable = 1'b1;
        wait_done();
        @(negedge clk); enable = 1'b0;
        $write("got:      "); print_bytes(32);
        $display("expected: 7f9c2ba4e88f827d616045507605853ed73b8093f6efbc88eb1a6eacfa66ef26");
        check256(256'h26ef66faac6e1aeb88bceff693803bd73e850576504560617d828fe8a42b9c7f, "SHAKE128 empty");
        $display("");
        repeat(4) @(posedge clk);

        // ------------------------------------------------------------
        // Test 4: SHAKE128 matrix_gen=1, 34-byte all-zero seed → 4×168B
        // (no fixed expected value — display squeeze outputs for inspection)
        // ------------------------------------------------------------
        $display("=== Test 4: SHAKE128 matrix_gen (34B zero seed, 4 squeezes) ===");
        @(negedge clk);
        hash_mode = 2'b10; matrix_gen = 1'b1;
        input_length = 16'd34; output_length = 16'd168;
        message_in = '0;
        enable = 1'b1;
        wait_done();
        @(negedge clk); enable = 1'b0;
        $write("squeeze0: "); print_bytes(32);
        $write("squeeze1: ");
        begin : sq1
            integer j;
            for (j = 0; j < 32; j = j + 1)
                $write("%h", message_out[(168+j)*8 +: 8]);
            $write("\n");
        end
        $display("");

        $display("=== All tests done ===");
        $finish;
    end

    initial begin
        #5000000;
        $display("GLOBAL TIMEOUT");
        $finish;
    end

endmodule
