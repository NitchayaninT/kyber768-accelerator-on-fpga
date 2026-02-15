// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps
`define DELAY 3
module sha3_256_tb;

  reg clk;
  reg enable;
  reg rst;
  reg [9471:0] in; // PK or random bits
  reg [13:0] input_len;
  wire [255:0] output_string; 
  wire done;

  sha3_256 sha3_256_uut (
      .clk(clk),
      .enable(enable),
      .rst(rst),
      .in(in),
      .input_len(input_len),
      .output_string(output_string),
      .done(done)
  );

 task print_state_bytes(input [255:0] S);
    integer b;
    localparam integer NUM_BYTES = 256 / 8;  // 32
    reg [255:0] python_order;
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

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, sha3_256_tb);
    $monitor("phase:%d\n perm_valid:%h\n perm_enable:%h\n total_bytes_index:%d\n block no:%d\n msg_len_bytes:%d\n stage_reg:%h\n input len:%d\n output string:%h\n ", sha3_256_uut.phase, sha3_256_uut.perm_valid, sha3_256_uut.perm_enable, sha3_256_uut.total_bytes_index, sha3_256_uut.absorb_idx, sha3_256_uut.msg_len_bytes, sha3_256_uut.state_reg, sha3_256_uut.input_len, sha3_256_uut.output_string);

    clk = 0;
    forever #(`DELAY / 2) clk = ~clk;
  end

  initial begin
    // -- INPUT -- //
    rst = 1;
    //in  = 256'hf8f11229044dfea54ddc214aaa439e7ea06b9b4ede8a3e3f6dfef500c9665598;
    //input_len = 14'd256; // for random bits
    in = 9472'h8d5296653d9efc336e4c509de356f58420fb64d5b2b4b4038ccca783dd92998e0f8047594efdabfb8a1d6274d9edeb50022687c8025ee1f7b835250c2527ccf2f0d9732169e36e2273204c7f9cf14868ef4c72496e4968935ac0fe16eb237021e4d6a4c88d406940ae2be286ea11df2ef6c8069dd44085cc8aa125d061360e1ecbbbe0382730c68e39a330d2a08ac3c61bd81c49935f652c4c4a65f8c5d8c9e5ff78c654e50776c4edbd5d1897748d6485b8103ebb5e18c90a4ce2fcbb569dd02a42050e47d99f9038c717ef5cc40576722915a7922c92833cacb6d6b852f92522183ac9ff2883a0edf53a8176c72f8f38ec9d21b722c467ab776faf607edeb9f531d7dc24dc7483ce83135b5590722581d41bce9d856c832ca4ca91767ef78c4fb003ed4bca4a073baf400834633c21091baf4bd972d949512ab5aef4ae28ee1b40bdb93fbf233a7e6ef23d19ac04361c542778d2d7e82d23044fb5f9904e1f6c05e684ec491266a22f5b965fa2faf13f94be7828fb0952da94a120453500cec5fc139c9d49d6d0488cdf54727096b580b7f627faa23d6d7de85723e3e1b24089b431fc443f504d12ff8f9ae0ae18bb529ac602a8d231bb4ba3b36ce3cbfb3f0f7588af7c023aef31b78d365a4eaaa1a0c74c5bee84ccc60f8fdbd25a63fc5834c0258a5e8b9dff8eb8ddc1764286f78cca0d80e7d0a75b851c492c46106649153f6fd2a4a4f0201edfea628f7163600852c1157fdaec5fa8739d30903798c955bf8b7b5bcf8978e73899d47b8b6f727673908da9539a9d9611dcd9a78b9ac5eba49636a5141d2870c44de592d38a21e7f7d23030eb0f36cdad724546c89904a7f41770764a3b82183f55fac498ef861151eb2ed49b9aa1eeefa3f90a903fdcd219be175550f14d99d5d7da93feed93479cf7dd8ce79994e453ac0d658ffcc55ad7e344137dd9593b4a7a399cecfc544e1b69a143d8c109ee52a4539d56dc6d2d05f60b1b3fbfd56bb8c0eed29dd719fff08c6e660c997b01018ce87b89eb561201da5bdb7df6df6b2745c5a5d103e9792f0fcec7ee1ea002cd80eb06c8b15e8a2fd09042af29bf31957a0aff91089141fb563796de9cfd4c363cc3df8b4f379804b2ee5fdf308b5ae9422a8245ef6b1a4ba1b773e73f5a559fe97105971c05215bb19074f6114a9f4fd3002af93d387b28f62d8a1d3a02101af18acb03a2aabe25d95b5f6c2c79a919b542ee6fc7f56c0d582c0a7ccf7a87d11a24b56b3c51b49d0d2cf007a4a35cb15754382e35bca557c8e8d2a0a423a478011bd1be05068b22850c06438d16a1b87dd3442ed0e0cc5b7967e071530f078cc5e582ae5cc750e030a6cfd400e9c4811ee32d70fa8417cb542ee6912dfb9f04eacb8e1b308c40bb4e0578dfb70d3b472353842685e2b53e743905b4de051e769c9899017aa83627619c66bc0a9d773bd8e85d0a62feed88d5013888180beb86bcf149981565557894374141558c4a24a7e3ca291d4080d81d5abe1e4cc0f4b7f7804041b8aa5c31f611cda10b447a7deb39e97c2025dd425a2a0ececbdfc0130376ad4d1e73468871dbd7313ce1e1c7902277cd763da144b58019c66ff33d93d4549e111c139266b2d575f524fde8dd8d534d6354671f5ddbb1fb14b8f64efb4d98b8f0afc7;
    input_len = 14'd9472; // for PK
    enable = 0;

    // Release reset to start loading state_reg, done, etc
    #(`DELAY) rst = 0;
    #(`DELAY) enable = 1;
    
    @(posedge done);
    #(`DELAY * 5);
    
    $display("\n\ndone : %b\n output string = %h\n", done, output_string);
    print_state_bytes(output_string);
    $finish;
  end
endmodule