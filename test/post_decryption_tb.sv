`timescale 1ns / 1ps
import params_pkg::*;

module post_decryption_tb;
    reg clk;
    reg enable; // when m_prime input is available
    reg prek_enable; // when pre_k input is available from compress encode
    reg rst;
    reg  [KYBER_N - 1:0] m_prime; // message from decryption
    reg  [KYBER_N - 1:0] pre_k; // from SK, used for sha3-512 to get coin prime and pre-k prime
    reg  [8703:0] ct; // ciphertext stream (c1,c2)
    reg [KYBER_N-1:0] coin; // coin is used to generate shared secret if ct matches. it is the component of SK
    reg [(KYBER_N * KYBER_RQ_WIDTH * KYBER_K)+KYBER_N-1:0] PK;
    wire f; // flag
    wire [KYBER_N-1:0] ss;
    wire decrypt_done;
    
    post_decryption post_decryption_uut (
        .clk         (clk),
        .enable      (enable),
        .prek_enable (prek_enable),
        .rst         (rst),
        .m_prime     (m_prime), // message from decryption
        .pre_k       (pre_k), // pre-k from pre-decryption
        .ct          (ct),
        .coin        (coin),
        .PK          (PK),
        .f           (f),
        .ss          (ss),
        .decrypt_done(decrypt_done)
    );
    always #1 clk = !clk;
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, post_decryption_tb);
        $monitor("ct enc = %h\n", post_decryption_uut.ct);
        $monitor("c_prime (dec) = %h\n", post_decryption_uut.c_prime); // c prime is used as a coin for re-encryption
        $monitor("pre_k_prime = %h\n", post_decryption_uut.pre_k_prime); // pre-k prime is used to generate shared secret if ct doesn't match 
        $monitor("f = %d\n", post_decryption_uut.f);
        $monitor("ct_coin_reg (coin | ct hashed) = %h\n", post_decryption_uut.ct_coin_reg);
        clk = 0;
    end
    
    initial begin
        // -- INPUT -- //
        integer i, j;
        rst = 1;
       
        m_prime = 256'hc8f62308b01ff532919f31937d33fd5e780b3695b97c34a45b51e0469fd4f63f; //placeholder first. the actual value comes from decryption's compress encode
        pre_k = 256'hb1a35cbe2ca105d1d76eda52a37f05abecc407b5f52c44945de57bce8cf21ffd; 
        coin = 256'h47741ccc6bbcc82300ce73c978d63f56c77a7c4170cab1a22e360612f1595435;
        PK = 9472'had3232fe1477823b785e687965a90cabfaacb8fa3438b6769ff64de7db23b6157904f50c5d6574584004652283082cb9850602c98029d0c1032e2a0305752f32f479ded62d2d2045e1f664492b185ed4229ca6b3d11ac8d609322292baec5316f3f6927ad7a644aa8c304884f6921ea8362fa80a43124a7116162c774b4fe076a506134c8dd0719330ae6f27ae89885a73599bb03b24484288e08b9a2fc359e4413060902059d49d0d0623ae185a406c1b14a21994ba59ad92c07df0c8ecc21cef285ef908493542450839b82b3a2b2d80919f53bca4f0339f272c2d2463d42ca1bb6584ca045b5997c4162877d8d22607b0a64c801b6113830ae99224499cece4aebdf738960b3ba0f48157971f47450c17b26fb7a6cf79f8972400ac4b3761f41cb03b0a9e7e892cef596b8df36f41ca3ed4f996ab5419185949a748a660f02c5db9c3f59449f14b4c56c213860848b5a93cbdfa4f850c8b7db219722073b7183898c24ccd28ac80779e8cd68f34c9cb8be8ae6fc9b4443c3c11581acb93639d14853b5c04556ccf1c3c2335cba0d4eb96b2c859998c5c16040bab9742a270380d53099ca01458744b10bb6b5eab8311b0bcc78189bf13c26c77b17c0b8a205a34d86453498aba72eb7c4886c5a8687c4974687bc4b1d72a4746f93a6afb7433c1ab17f62c5f008eccc4240a04778b3b78024c69c458cd6d1646cb8241ecc56c671389102647a4f6adf8e118da7320e5ca815195410b293ec685228d09bb28447ace58856780ae015219ebe288f3fc5e48c16655e3984815378268a36c54582a943995019a6744927f5185705a0f24fb8ccf39731f84accd043641059926488b473b4bf7f05ca23168aa31b92757797c498ac0fb6acea2a01e9c48fb5701d76c6d6c16a2477b45d661a7b43b54b04453fb95ab98f8bb7ab882bdc58d4fc57b2c67ce89699cfeb428cf79159d7c7c566299d2739e8f5cae5f045f6ec310fbd514e8e8606b89555aa244908894b1000c7ea5847ffbc1cac05cb39cbf3ca31f6981b44b26c7a8e348a0188ae0f9ab715171ed44a02cfb8542e124330694d4d6790a03675dc8a836ec74137515a3326ea4c45307b9281ae8614ef802e96617a658bbe472b4fe24c3e442224bca97a6036c4b35378958396e10b59dac043b94355caab153e1028993214b021fafa6645f8782e73197fd2c1338ec7e13f7c4916b14c46236c6c16e329c3ba262bf24e4cbd32046101bc4f3384dafa02bbfb437afd6700a6a3ff33b50efb644cf8604dc679be45ac9701087954254d6ba36c3a8c6198c5b8f66320339266ee785ca163d29bb027c6789eb107f63575e7bb662080a6601a6bd7bf0b97e26c134b52e451c273bac73c721cc553b304d5a5c6667baae834eb4673ca7d357934a802d5897be46a4113a51f7c37a36e8314f4b1cf6f8b470e83516718faf1c53d53074442946d6b9380502b24139a46749254a85286dc3c9b3fc3fc9183dbe3382d39a6894d4a044e4a3c1a250f860913d30c8177c30d3d615ffec0ee1c6b4f474c015585788a394684489621656485c4b3ada1097ec8f38e9907cc9ad2fd912ded0ae04f94556c7244d149cec555f56a052aae45433e794a2bf83f3b0ccbafc641b30537391aae33d78b6514694f949ecc8cd545da37bca;    
        ct = 8704'hca176818610cb5572ba910bd1773f071291c1e99210802ff7d97de52cf3d3ff017520fad07bfada4bcbc9a6a2f9fafc77df48596336016b6c038455e75920c7b08b2983d33f83016c1371b05db098008c02bbab0815ca5a85d3c88b9c8da495b135aad7477f9be0642cf15583d9de75d591b6322b9256e96149efce11085605b8575e926cebafd10860697c5f59545530fb6fe2a6d1b826510c7f43c8374734cd4ebe3708eed2738b42d49bb23bb3e534ae5987a4ffa986e2be27bcc0f10b3a5cae0c00963871c675031b4ad090ebbeec1a2ca24727faa7df41f21e7d340cde775e38d1fa29dc85bc2d15186394fad37c74e1c0387b0d9b6630b15b0e5bd3156f84d972c6f7b2763198d5fab6e36de227585915b167dfc5ae7e9d0229bb596e211db8b3bca38825fb3f411876aa4bcbbee82686220d791e3caca93cc9bc7e23af91ea22c624151cac9380023e32b5aaa5a7d9c6ca271908aa03b093147786cce2be77385b864d5ba6061b25ef721ce5b7238961891d761ab93731fe030d870fe66d72a824972443940d587b5cc73dbaed8b061efde2710ce4749a24bc6f02fbb9c127f206f2b8aac5414a101aa09c7797bca61b0aa94830bd4ba3d18a89fb84bb1ec7ae478074a548f359183a828825d31edea61a2f695054c3ce0f7cfa0915c2a52d18cb5e2680d330873e7c055bd0c298be29d6353532a2bce4940b50a2a8a11f056db00e19d658b2dd0b3b69dc4b3553e478d7dff292294e51a380b5adc54b5526c262170ad4bd61f67c961cf00fd7690a4250dd32e05466b49f651ab2d500c5f56410a40f23b7f83459111a89c0e7a3468a9a0de0b746b735336d87b14fd8c2cde69da5b0f1efb275c24956c687befe390679e9ed24f20c6c28c50f93e5d87037492274c5889909de7db5c57cb7e12c5d202d8f6e4a0430b42ed1f07c23efd55881b4a4d188f5b0744a6a2dd4fb95e6a36fa56124464624e305d241b6e172fd8c3dc4a786902b06a6b366d26f38f8b1f0e11554f97c4274ec5875bf1f82ade92540fdf545673a729f960afd79911a6e3caeee9d9947ba04809bcf3922d308f2e38e386ad17794d0a1b58a4b567b2487e0e3ac6021841124ea2513b4286f0687114d4f2f1eee721772d54328d4e05fc07fe44cddd707bc9e4410332c85b9b5758119d873c8d3209de53b1440278ccfd435945e1d39774b1f1cbde135cedea1dd097955f0f545654d73824b422cc26edec2e86e6f7a3ebef5e566a5ce7305cc1cc1a0d3de7446041d11020b98f5d542339a97f68a83e3a0215b0db3ac95f8e1c9955e89370b22bf5c340155587ce44fa26c758378f5b357fa6d258362a34ed3e302d0baab63d695c0b4bc370da4b04fd02e41a2543c3a39b49337947affe689fa58991efd3d448f8f74b78f5ccff0b2f2330350a279f7c577605e0527cc83e0510d9a5ac2535c2b744601dd71e3b40ecef4b67116ad077f17c0c37fe394d74ea3bc892fb4e2b28b61aabbe5852be736dc858726a89ca571955bf81f9a783af;

        enable = 0;
        prek_enable = 0;

        // hold reset for a few cycles
        repeat (5) @(posedge clk);
        rst = 0;

        // wait a cycle, then pulse start
        repeat (2) @(posedge clk);
        enable = 1; // suppose
        prek_enable = 1; // suppose

        
        $display("Mode : %d",post_decryption_uut.encrypt_post_dec.mode); // enc = 0, dec = 1
        wait(decrypt_done == 1);
        $display("Decryption done. f = %d, ss = %h", f, ss);
    end
endmodule