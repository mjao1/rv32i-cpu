module tb_data_memory ();
  logic clk_w;
  logic [31:0] addr_w;
  logic [31:0] write_data_w;
  logic mem_write_w;
  logic [2:0] funct3_w;
  logic [31:0] read_data_w;

  data_memory #(
    .MEM_SIZE (256)
  ) u_data_memory (
    .clk_i (clk_w),
    .addr_i (addr_w),
    .write_data_i (write_data_w),
    .mem_write_i (mem_write_w),
    .funct3_i (funct3_w),
    .read_data_o (read_data_w)
  );

  int test_count_r = 0;
  int pass_count_r = 0;

  initial clk_w = 0;
  always #5 clk_w = ~clk_w;

  task automatic write_mem(
    input logic [31:0] addr,
    input logic [31:0] data,
    input logic [2:0] f3
  );
    addr_w = addr;
    write_data_w = data;
    funct3_w = f3;
    mem_write_w = 1'b1;
    @(posedge clk_w);
    #1;
    mem_write_w = 1'b0;
  endtask

  task automatic check_read(
    input string name,
    input logic [31:0] addr,
    input logic [2:0] f3,
    input logic [31:0] expected
  );
    addr_w = addr;
    funct3_w = f3;
    mem_write_w = 1'b0;
    #1;

    test_count_r++;
    if (read_data_w === expected) begin
      pass_count_r++;
    end else begin
      $display("FAIL: %-20s addr=0x%08h f3=%0b got=0x%08h expected=0x%08h", name, addr, f3, read_data_w, expected);
    end
  endtask

  initial begin
    mem_write_w = 1'b0;
    addr_w = 32'b0;
    write_data_w = 32'b0;
    funct3_w = 3'b010;
    @(posedge clk_w);
    #1;

    // SW then LW
    write_mem(32'h0000_0000, 32'hAABB_CCDD, 3'b010);
    check_read("SW/LW", 32'h0000_0000, 3'b010, 32'hAABB_CCDD);

    // LB (signed byte reads, little-endian)
    check_read("LB byte0", 32'h0000_0000, 3'b000, 32'hFFFF_FFDD); // 0xDD signext
    check_read("LB byte1", 32'h0000_0001, 3'b000, 32'hFFFF_FFCC); // 0xCC signext
    check_read("LB byte2", 32'h0000_0002, 3'b000, 32'hFFFF_FFBB); // 0xBB signext
    check_read("LB byte3", 32'h0000_0003, 3'b000, 32'hFFFF_FFAA); // 0xAA signext

    // LBU (unsigned byte reads)
    check_read("LBU byte0", 32'h0000_0000, 3'b100, 32'h0000_00DD);
    check_read("LBU byte3", 32'h0000_0003, 3'b100, 32'h0000_00AA);

    // LH (signed halfword, little-endian)
    check_read("LH half0", 32'h0000_0000, 3'b001, 32'hFFFF_CCDD); // 0xCCDD signext
    check_read("LH half2", 32'h0000_0002, 3'b001, 32'hFFFF_AABB); // 0xAABB signext

    // LHU (unsigned halfword)
    check_read("LHU half0", 32'h0000_0000, 3'b101, 32'h0000_CCDD);
    check_read("LHU half2", 32'h0000_0002, 3'b101, 32'h0000_AABB);

    // SB (store byte)
    write_mem(32'h0000_0010, 32'h0000_00FF, 3'b000);
    check_read("SB/LBU", 32'h0000_0010, 3'b100, 32'h0000_00FF);
    check_read("SB/LB sign", 32'h0000_0010, 3'b000, 32'hFFFF_FFFF);

    // SH (store halfword)
    write_mem(32'h0000_0020, 32'h0000_0000, 3'b010); // clear word first
    write_mem(32'h0000_0020, 32'h0000_1234, 3'b001);
    check_read("SH/LHU", 32'h0000_0020, 3'b101, 32'h0000_1234);
    check_read("SH/LW low half", 32'h0000_0020, 3'b010, 32'h0000_1234);

    // Positive byte (no sign extension)
    write_mem(32'h0000_0030, 32'h0000_007F, 3'b000);
    check_read("LB pos", 32'h0000_0030, 3'b000, 32'h0000_007F);

    // Positive halfword (no sign extension)
    write_mem(32'h0000_0040, 32'h0000_7ABC, 3'b001);
    check_read("LH pos", 32'h0000_0040, 3'b001, 32'h0000_7ABC);

    // Write disabled
    write_data_w = 32'hFFFF_FFFF;
    addr_w = 32'h0000_0000;
    funct3_w = 3'b010;
    mem_write_w = 1'b0;
    @(posedge clk_w);
    #1;
    check_read("wen=0 no write", 32'h0000_0000, 3'b010, 32'hAABB_CCDD);

    $display("PASSED: %0d", pass_count_r);
    $display("FAILED: %0d", test_count_r - pass_count_r);

    $finish;
  end

endmodule
