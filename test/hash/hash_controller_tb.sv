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
    logic [5375:0] message_out;
    logic          valid;

    // BRAM write port
    logic        msg_wr_en;
    logic [10:0] msg_wr_addr;
    logic [ 7:0] msg_wr_data;

    hash_controller dut (
        .clk         (clk),
        .rst         (rst),
        .msg_wr_en   (msg_wr_en),
        .msg_wr_addr (msg_wr_addr),
        .msg_wr_data (msg_wr_data),
        .enable      (enable),
        .hash_mode   (hash_mode),
        .matrix_gen  (matrix_gen),
        .input_length(input_length),
        .message_out (message_out),
        .valid       (valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, hash_controller_tb);
    end

    // Write n_bytes to BRAM one byte per cycle from a flat array
    // (caller must ensure bytes[] is large enough)
    task automatic load_bram;
        input integer  n_bytes;
        input [9471:0] bytes;   // byte 0 at bits [7:0], byte 1 at [15:8], …
        integer b;
        for (b = 0; b < n_bytes; b = b + 1) begin
            @(negedge clk);
            msg_wr_en   = 1'b1;
            msg_wr_addr = b[10:0];
            msg_wr_data = bytes[8*b +: 8];
        end
        @(negedge clk);
        msg_wr_en = 1'b0;
    endtask

    // Wait for valid, timeout after n_max cycles
    task automatic wait_done;
        integer i;
        i = 0;
        while (!valid) begin
            @(posedge clk); #1;
            i = i + 1;
            if (i > 400000) begin
                $display("TIMEOUT");
                $finish;
            end
        end
    endtask

    task automatic print_bytes;
        input integer n_bytes;
        integer j;
        for (j = 0; j < n_bytes; j = j + 1)
            $write("%02h", message_out[8*j +: 8]);
        $write("\n");
    endtask

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
        msg_wr_en = 1'b0; msg_wr_addr = '0; msg_wr_data = '0;
        hash_mode = 2'b00; matrix_gen = 1'b0; input_length = 16'd0;
        repeat(4) @(posedge clk);
        @(negedge clk); rst = 1'b0;
        repeat(2) @(posedge clk);

        // ------------------------------------------------------------
        // Test 1: SHA3-256 empty string (0 bytes, no BRAM write needed)
        // Expected: a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a
        // ------------------------------------------------------------
        $display("=== Test 1: SHA3-256 empty string ===");
        @(negedge clk);
        hash_mode    = 2'b00;
        matrix_gen   = 1'b0;
        input_length = 16'd0;
        enable = 1'b1;
        @(negedge clk); enable = 1'b0;
        wait_done();
        $write("got:      "); print_bytes(32);
        $display("expected: a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a");
        check256(256'h4a43f8804b0ad882fa493be44dff80f562d661a05647c15166d71ebff8c6ffa7, "SHA3-256 empty");
        $display("");
        repeat(4) @(posedge clk);

        // ------------------------------------------------------------
        // Test 2: SHA3-256 "abc" (3 bytes: 0x61 0x62 0x63)
        // Expected: 3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532
        // ------------------------------------------------------------
        $display("=== Test 2: SHA3-256 'abc' (3 bytes) ===");
        begin : t2
            logic [9471:0] msg;
            msg = '0;
            msg[7:0]   = 8'h61;
            msg[15:8]  = 8'h62;
            msg[23:16] = 8'h63;
            load_bram(3, msg);
        end
        @(negedge clk);
        hash_mode    = 2'b00;
        matrix_gen   = 1'b0;
        input_length = 16'd3;
        enable = 1'b1;
        @(negedge clk); enable = 1'b0;
        wait_done();
        $write("got:      "); print_bytes(32);
        $display("expected: 3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532");
        check256(256'h3215431145e2bf465b529d3e6e085f85bd90d36b2d175c04b225e24fa75d983a, "SHA3-256 abc");
        $display("");
        repeat(4) @(posedge clk);

        // ------------------------------------------------------------
        // Test 3: SHAKE128 empty string (no matrix_gen, 1 squeeze = 168B)
        // Expected first 32B: 7f9c2ba4e88f827d616045507605853ed73b8093f6efbc88eb1a6eacfa66ef26
        // ------------------------------------------------------------
        $display("=== Test 3: SHAKE128 empty string (no matrix_gen) ===");
        @(negedge clk);
        hash_mode    = 2'b10;
        matrix_gen   = 1'b0;
        input_length = 16'd0;
        enable = 1'b1;
        @(negedge clk); enable = 1'b0;
        wait_done();
        $write("got:      "); print_bytes(32);
        $display("expected: 7f9c2ba4e88f827d616045507605853ed73b8093f6efbc88eb1a6eacfa66ef26");
        check256(256'h26ef66faac6e1aeb88bceff693803bd73e850576504560617d828fe8a42b9c7f, "SHAKE128 empty");
        $display("");
        repeat(4) @(posedge clk);

        // ------------------------------------------------------------
        // Test 4: SHAKE128 matrix_gen=1, 34-byte all-zero seed → 4×168B
        // ------------------------------------------------------------
        $display("=== Test 4: SHAKE128 matrix_gen (34B zero seed, 4 squeezes) ===");
        begin : t4
            logic [9471:0] msg;
            msg = '0;  // 34 zero bytes
            load_bram(34, msg);
        end
        @(negedge clk);
        hash_mode    = 2'b10;
        matrix_gen   = 1'b1;
        input_length = 16'd34;
        enable = 1'b1;
        @(negedge clk); enable = 1'b0;
        wait_done();
        $write("squeeze0: "); print_bytes(32);
        $write("squeeze1: ");
        begin : sq1
            integer j;
            for (j = 0; j < 32; j = j + 1)
                $write("%02h", message_out[(168+j)*8 +: 8]);
            $write("\n");
        end
        $display("");

        $display("=== All tests done ===");
        $finish;
    end

    initial begin
        #50000000;
        $display("GLOBAL TIMEOUT");
        $finish;
    end

endmodule
