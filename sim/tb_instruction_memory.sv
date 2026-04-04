module tb_instruction_memory ();
  logic clk_w;
  logic write_en_w;
  logic [31:0] write_addr_w;
  logic [31:0] write_data_w;
  logic [31:0] addr_w;
  logic [31:0] instruction_w;

  instruction_memory #(
    .MEM_SIZE (256)
  ) u_instruction_memory (
    .clk_i (clk_w),
    .write_en_i (write_en_w),
    .write_addr_i (write_addr_w),
    .write_data_i (write_data_w),
    .addr_i (addr_w),
    .instruction_o (instruction_w)
  );

  int test_count_r = 0;
  int pass_count_r = 0;

  initial clk_w = 0;
  always #5 clk_w = ~clk_w;

  task automatic write_word(
    input logic [31:0] addr,
    input logic [31:0] data
  );
    write_addr_w = addr;
    write_data_w = data;
    write_en_w = 1'b1;
    @(posedge clk_w);
    #1;
    write_en_w = 1'b0;
  endtask

  task automatic check(
    input string name,
    input logic [31:0] addr,
    input logic [31:0] expected
  );
    addr_w = addr;
    #1;

    test_count_r++;
    if (instruction_w === expected) begin
      pass_count_r++;
    end else begin
      $display("FAIL: %-20s addr=0x%08h got=0x%08h expected=0x%08h", name, addr, instruction_w, expected);
    end
  endtask

  initial begin
    write_en_w = 1'b0;
    write_addr_w = 32'b0;
    write_data_w = 32'b0;
    addr_w = 32'b0;
    @(posedge clk_w);
    #1;

    // Load program via write port
    write_word(32'h0000_0000, 32'h0050_0093); // ADDI x1, x0, 5
    write_word(32'h0000_0004, 32'h00A0_0113); // ADDI x2, x0, 10
    write_word(32'h0000_0008, 32'h0020_81B3); // ADD x3, x1, x2
    write_word(32'h0000_000C, 32'h4020_8233); // SUB x4, x1, x2

    check("word 0", 32'h0000_0000, 32'h0050_0093);
    check("word 1", 32'h0000_0004, 32'h00A0_0113);
    check("word 2", 32'h0000_0008, 32'h0020_81B3);
    check("word 3", 32'h0000_000C, 32'h4020_8233);

    // Unaligned addresses still index by word (bits [31:2])
    check("unalign", 32'h0000_0001, 32'h0050_0093);
    check("unalign2", 32'h0000_0007, 32'h00A0_0113);

    $display("PASSED: %0d", pass_count_r);
    $display("FAILED: %0d", test_count_r - pass_count_r);

    $finish;
  end

endmodule
