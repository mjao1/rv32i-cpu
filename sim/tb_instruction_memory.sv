module tb_instruction_memory ();
  logic [31:0] addr_w;
  logic [31:0] instruction_w;

  instruction_memory #(
    .MEM_SIZE (256),
    .MEM_INIT ("test/programs/test_imem.hex")
  ) u_instruction_memory (
    .addr_i (addr_w),
    .instruction_o (instruction_w)
  );

  int test_count_r = 0;
  int pass_count_r = 0;

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
    // test_imem.hex:
    // addr 0x00: 00500093 (ADDI x1, x0, 5)
    // addr 0x04: 00A00113 (ADDI x2, x0, 10)
    // addr 0x08: 002081B3 (ADD  x3, x1, x2)
    // addr 0x0C: 40208233 (SUB  x4, x1, x2)

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
