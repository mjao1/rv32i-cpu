module tb_rv32i_cpu import rv32i_pkg::*; ();
  logic clk_w;
  logic rst_w;
  logic imem_write_en_w;
  logic [31:0] imem_write_addr_w;
  logic [31:0] imem_write_data_w;

  rv32i_cpu #(
    .IMEM_SIZE (256),
    .DMEM_SIZE (256)
  ) u_rv32i_cpu (
    .clk_i (clk_w),
    .rst_i (rst_w),
    .imem_write_en_i (imem_write_en_w),
    .imem_write_addr_i (imem_write_addr_w),
    .imem_write_data_i (imem_write_data_w)
  );

  int test_count_r = 0;
  int pass_count_r = 0;

  initial clk_w = 0;
  always #5 clk_w = ~clk_w;

  task automatic load_word(
    input logic [31:0] addr,
    input logic [31:0] data
  );
    imem_write_addr_w = addr;
    imem_write_data_w = data;
    imem_write_en_w = 1'b1;
    @(posedge clk_w);
    #1;
    imem_write_en_w = 1'b0;
  endtask

  task automatic check_reg(
    input string name,
    input int reg_idx,
    input logic [31:0] expected
  );
    logic [31:0] actual;
    actual = u_rv32i_cpu.u_register_file.regs_r[reg_idx];
    test_count_r++;
    if (actual === expected) begin
      pass_count_r++;
    end else begin
      $display("FAIL: %s x%0d=0x%08h expected=0x%08h", name, reg_idx, actual, expected);
    end
  endtask

  task automatic check_mem (
    input string name,
    input int addr,
    input logic [7:0] expected
  );
    logic [7:0] actual;
    actual = u_rv32i_cpu.u_data_memory.mem_r[addr];
    test_count_r++;
    if (actual === expected) begin
      pass_count_r++;
    end else begin
      $display("FAIL: %s mem[%0d]=0x%02h expected=0x%02h", name, addr, actual, expected);
    end
  endtask

  initial begin
    rst_w = 1'b1;
    imem_write_en_w = 1'b0;
    imem_write_addr_w = 32'b0;
    imem_write_data_w = 32'b0;
    @(posedge clk_w);
    #1;

    // Load program via write port
    load_word(32'h00, 32'h00500093); // ADDI x1, x0, 5
    load_word(32'h04, 32'h00A00113); // ADDI x2, x0, 10
    load_word(32'h08, 32'h002081B3); // ADD x3, x1, x2
    load_word(32'h0C, 32'h40110233); // SUB x4, x2, x1
    load_word(32'h10, 32'h0020F2B3); // AND x5, x1, x2
    load_word(32'h14, 32'h0020E333); // OR x6, x1, x2
    load_word(32'h18, 32'h00302023); // SW x3, 0(x0)
    load_word(32'h1C, 32'h00002383); // LW x7, 0(x0)
    load_word(32'h20, 32'h00F00413); // ADDI x8, x0, 15
    load_word(32'h24, 32'h00838463); // BEQ x7, x8, +8
    load_word(32'h28, 32'h00100493); // ADDI x9, x0, 1 (skipped)
    load_word(32'h2C, 32'h00200513); // ADDI x10, x0, 2

    rst_w = 1'b0;

    // Run 14 cycles
    repeat (14) @(posedge clk_w);
    #1;

    // Verify register values
    check_reg("ADDI x1", 1, 32'h0000_0005);
    check_reg("ADDI x2", 2, 32'h0000_000A);
    check_reg("ADD x3", 3, 32'h0000_000F);
    check_reg("SUB x4", 4, 32'h0000_0005);
    check_reg("AND x5", 5, 32'h0000_0000);
    check_reg("OR x6", 6, 32'h0000_000F);
    check_reg("LW x7", 7, 32'h0000_000F);
    check_reg("ADDI x8", 8, 32'h0000_000F);
    check_reg("BEQ skip x9", 9, 32'h0000_0000); // skipped
    check_reg("ADDI x10", 10, 32'h0000_0002);

    // Verify data memory
    check_mem("mem[0]", 0, 8'h0F);
    check_mem("mem[1]", 1, 8'h00);
    check_mem("mem[2]", 2, 8'h00);
    check_mem("mem[3]", 3, 8'h00);

    $display("PASSED: %0d", pass_count_r);
    $display("FAILED: %0d", test_count_r - pass_count_r);

    $finish;
  end

endmodule
