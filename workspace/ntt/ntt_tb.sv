module ntt_tb;
  reg [15:0] in[256];
  wire [(16*256)-1:0] out;
  reg clk;
  reg reset;
  reg enable;
  wire valid;

  ntt uut (
      .clk(clk),
      .enable(enable),
      .in(in),
      .reset(reset),
      .out(out),
      .valid(valid)
  );

  wire [3:0] clt_set;
  wire [3:0] stage;
  wire [3:0] step;
  wire[7:0] start, len, k, j;
  wire [(16*256) - 1: 0] buf_in;
  wire [15:0] buf_out[256];
  wire [15:0] a[8],b[8], zeta[8], out0[8], out1[8];
  wire read;

  assign read = uut.read;
  assign clt_set = uut.cooley_tookey_set;
  assign stage = uut.stage;
  assign step = uut.step;
  assign start = uut.start;
  assign len = uut.len;
  assign k = uut.k;
  assign j = uut.j;
  assign buf_in = uut.buf_in;
  genvar i;

  for (i=0; i<8;i++) begin: g_debug_clt
    assign a[i] = uut.a[i];
    assign b[i] = uut.b[i];
    assign zeta[i] = uut.zeta[i];
    assign out0[i] = uut.out0[i];
    assign out1[i] = uut.out1[i];
  end

  for (i=0; i<256;i++)begin : g_debug_buf_out
    assign buf_out[i] = uut.buf_out[16*i +: 16];
  end


  reg [7:0] prev_step = 0;
  //reg[2:0] prev_stage = 7;
  always @(posedge clk) begin
    if(uut.step!= prev_step) begin
      $display("time:%t step : %h, j : %d , len : %d, stage: %d\nbuf_in:%h\nbuf_out:%h\n",
        $time,uut.step, uut.j, uut.len, uut.stage, uut.buf_in, uut.buf_out);
      prev_step <= uut.step;
    end
  end
  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  initial begin
    $readmemb("test_vect.bin", in);
    enable = 0;
    reset = 1;
    #10 reset = 0;enable = 1;
    wait(valid);
    $display("----------------Done!---------------");
    $display("out:%h", out);
    $finish;
  end
endmodule
