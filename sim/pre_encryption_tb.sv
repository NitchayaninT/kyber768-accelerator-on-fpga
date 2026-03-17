// NOTE : this is the old version of TB does not work with current hdl
`timescale 1ns / 1ps
`define DELAY 3
import params_pkg::*;

module pre_encryption_tb;
  reg clk;
  reg start;
  reg rst;
  reg [KYBER_N - 1:0] r_in;
  reg [(KYBER_N)+(KYBER_K * KYBER_RQ_WIDTH * KYBER_N)-1:0] encryption_key;
  wire signed [KYBER_POLY_WIDTH-1:0] e2[0:KYBER_N-1];
  wire signed [KYBER_POLY_WIDTH-1:0] e1[0:KYBER_K-1][0:KYBER_N-1];
  wire signed [KYBER_POLY_WIDTH-1:0] r[0:KYBER_K-1][0:KYBER_N-1];
  wire signed [(KYBER_N * KYBER_RQ_WIDTH)-1:0] t_vec[3];
  wire signed [KYBER_POLY_WIDTH-1 : 0] a_t[0:(KYBER_K*KYBER_K)-1][0:KYBER_N-1];
  wire signed [KYBER_POLY_WIDTH-1 : 0] msg_poly[0:KYBER_N-1];
  wire [KYBER_N - 1:0] pre_k;
  wire valid;

  reg [15:0] coeff;
  reg [11:0] coeff_12;

  pre_encryption pre_encryption_uut (
      .clk           (clk),
      .start         (start),
      .rst           (rst),
      .r_in          (r_in),
      .encryption_key(encryption_key),
      .e2            (e2),
      .e1            (e1),
      .r             (r),
      .t_vec         (t_vec),
      .a_t           (a_t),
      .msg_poly      (msg_poly),
      .pre_k         (pre_k),
      .valid         (valid)
  );

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, pre_encryption_tb);
    //$monitor("total byte index : %d, msg len bytes %d, absorb byte : %h",pre_encryption_uut.sha3_uut3.total_bytes_index,pre_encryption_uut.sha3_uut3.msg_len_bytes, pre_encryption_uut.sha3_uut3.absorb_byte);
    //$monitor("phase : %d, rate_block: %h, state reg 512 : %h",pre_encryption_uut.sha3_uut3.phase,pre_encryption_uut.sha3_uut3.rate_block,  pre_encryption_uut.sha3_uut3.state_reg);
  
    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end

  integer i, j, k;
  initial begin
    // -- INPUT -- //
    rst = 1;
    r_in = 256'hf8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598;
    encryption_key = 9472'h8d5296653d9efc336e4c509de356f58420fb64d5b2b4b4038ccca783dd92998e0f8047594efdabfb8a1d6274d9edeb50022687c8025ee1f7b835250c2527ccf2f0d9732169e36e2273204c7f9cf14868ef4c72496e4968935ac0fe16eb237021e4d6a4c88d406940ae2be286ea11df2ef6c8069dd44085cc8aa125d061360e1ecbbbe0382730c68e39a330d2a08ac3c61bd81c49935f652c4c4a65f8c5d8c9e5ff78c654e50776c4edbd5d1897748d6485b8103ebb5e18c90a4ce2fcbb569dd02a42050e47d99f9038c717ef5cc40576722915a7922c92833cacb6d6b852f92522183ac9ff2883a0edf53a8176c72f8f38ec9d21b722c467ab776faf607edeb9f531d7dc24dc7483ce83135b5590722581d41bce9d856c832ca4ca91767ef78c4fb003ed4bca4a073baf400834633c21091baf4bd972d949512ab5aef4ae28ee1b40bdb93fbf233a7e6ef23d19ac04361c542778d2d7e82d23044fb5f9904e1f6c05e684ec491266a22f5b965fa2faf13f94be7828fb0952da94a120453500cec5fc139c9d49d6d0488cdf54727096b580b7f627faa23d6d7de85723e3e1b24089b431fc443f504d12ff8f9ae0ae18bb529ac602a8d231bb4ba3b36ce3cbfb3f0f7588af7c023aef31b78d365a4eaaa1a0c74c5bee84ccc60f8fdbd25a63fc5834c0258a5e8b9dff8eb8ddc1764286f78cca0d80e7d0a75b851c492c46106649153f6fd2a4a4f0201edfea628f7163600852c1157fdaec5fa8739d30903798c955bf8b7b5bcf8978e73899d47b8b6f727673908da9539a9d9611dcd9a78b9ac5eba49636a5141d2870c44de592d38a21e7f7d23030eb0f36cdad724546c89904a7f41770764a3b82183f55fac498ef861151eb2ed49b9aa1eeefa3f90a903fdcd219be175550f14d99d5d7da93feed93479cf7dd8ce79994e453ac0d658ffcc55ad7e344137dd9593b4a7a399cecfc544e1b69a143d8c109ee52a4539d56dc6d2d05f60b1b3fbfd56bb8c0eed29dd719fff08c6e660c997b01018ce87b89eb561201da5bdb7df6df6b2745c5a5d103e9792f0fcec7ee1ea002cd80eb06c8b15e8a2fd09042af29bf31957a0aff91089141fb563796de9cfd4c363cc3df8b4f379804b2ee5fdf308b5ae9422a8245ef6b1a4ba1b773e73f5a559fe97105971c05215bb19074f6114a9f4fd3002af93d387b28f62d8a1d3a02101af18acb03a2aabe25d95b5f6c2c79a919b542ee6fc7f56c0d582c0a7ccf7a87d11a24b56b3c51b49d0d2cf007a4a35cb15754382e35bca557c8e8d2a0a423a478011bd1be05068b22850c06438d16a1b87dd3442ed0e0cc5b7967e071530f078cc5e582ae5cc750e030a6cfd400e9c4811ee32d70fa8417cb542ee6912dfb9f04eacb8e1b308c40bb4e0578dfb70d3b472353842685e2b53e743905b4de051e769c9899017aa83627619c66bc0a9d773bd8e85d0a62feed88d5013888180beb86bcf149981565557894374141558c4a24a7e3ca291d4080d81d5abe1e4cc0f4b7f7804041b8aa5c31f611cda10b447a7deb39e97c2025dd425a2a0ececbdfc0130376ad4d1e73468871dbd7313ce1e1c7902277cd763da144b58019c66ff33d93d4549e111c139266b2d575f524fde8dd8d534d6354671f5ddbb1fb14b8f64efb4d98b8f0afc7;
    start = 0;
    // Release reset to start loading state_reg, done, etc
    #(`DELAY) rst = 0;
    #(`DELAY) start = 1;

    wait (pre_encryption_uut.sha3_valid[0]);
    $display("m = %h", pre_encryption_uut.msg);
    wait (pre_encryption_uut.sha3_valid[1]);
    $display("hash_ek = %h", pre_encryption_uut.hash_ek);
    wait (pre_encryption_uut.sha512_valid);
    $display("buf0 = %h", pre_encryption_uut.buf0);
    wait (pre_encryption_uut.noise_gen_valid);
    $display("buf1(kr) = %h", pre_encryption_uut.buf1);
    $display("coin = %h", pre_encryption_uut.coin);
    $display("pre_k = %h", pre_encryption_uut.pre_k);
    $display("t0_first48bits = %h", pre_encryption_uut.t_vec[0][47:0]);


    wait (valid == 1'b1);

    #(`DELAY);

    // Display T_trans
    $display("T_TRANS POLYS VECTOR");
    for (j = 0; j < 3; j++) begin
      $display("=== t_vec Poly %0d ===", j);
      for (i = 0; i < 256; i++) begin
        // pack 16 unpacked bits into a packed vector
        coeff_12 = t_vec[j][i*12+:12];
        $write("%0d ", coeff_12);
        if ((i % 16) == 15) $write("\n");
      end
      $write("\n");
    end
    // Display msg poly
    $display("MSG POLY");
    for (i = 0; i < 256; i++) begin
      coeff_12 = msg_poly[i*12+:12];
      $write("%0d ", coeff_12);
      if ((i % 16) == 15) $write("\n");
    end
    $write("\n");
    // Display public matrix
    $display("PUBLIC MATRIX POLYS");
    for (j = 0; j < 9; j++) begin
      $display("=== Poly %0d ===", j);
      for (i = 0; i < 256; i++) begin
        // pack 16 unpacked bits into a packed vector
        coeff = a_t[j][i];
        $write("%0d ", coeff);
        if ((i % 16) == 15) $write("\n");
      end
      $write("\n");
    end

    $display("NOISE POLYS");
    for (j = 0; j < 3; j++) begin
      $display("=== r %0d ===", j);
      for (i = 0; i < 256; i++) begin
        // pack 16 unpacked bits into a packed vector
        coeff = r[j][i];
        $write("%0d ", coeff);
        if ((i % 16) == 15) $write("\n");
      end
      $write("\n");
    end

    for (k = 0; k < 3; k++) begin
      $display("=== e1 %0d ===", k);
      for (i = 0; i < 256; i++) begin
        // pack 16 unpacked bits into a packed vector
        coeff = e1[k][i];
        $write("%0d ", coeff);
        if ((i % 16) == 15) $write("\n");
      end
      $write("\n");
    end


    $display("=== e2 ===");
    for (i = 0; i < 256; i++) begin
      // pack 16 unpacked bits into a packed vector
      coeff = e2[i];
      $write("%0d ", coeff);
      if ((i % 16) == 15) $write("\n");
    end
    $write("\n");

  end
endmodule

