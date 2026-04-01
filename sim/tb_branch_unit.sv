module tb_branch_unit import rv32i_pkg::*; ();
  logic [31:0] rs1_data_w;
  logic [31:0] rs2_data_w;
  branch_op_t branch_op_w;
  logic branch_w;
  logic branch_taken_w;

  branch_unit u_branch_unit (
    .rs1_data_i (rs1_data_w),
    .rs2_data_i (rs2_data_w),
    .branch_op_i (branch_op_w),
    .branch_i (branch_w),
    .branch_taken_o (branch_taken_w)
  );

  int test_count_r = 0;
  int pass_count_r = 0;

  task automatic check(
    input string name,
    input logic [31:0] rs1,
    input logic [31:0] rs2,
    input branch_op_t op,
    input logic br,
    input logic expected
  );
    rs1_data_w = rs1;
    rs2_data_w = rs2;
    branch_op_w = op;
    branch_w = br;
    #1;

    test_count_r++;
    if (branch_taken_w === expected) begin
      pass_count_r++;
    end else begin
      $display("FAIL: %-20s rs1=0x%08h rs2=0x%08h op=%0d br=%0b got=%0b expected=%0b",
               name, rs1, rs2, op, br, branch_taken_w, expected);
    end
  endtask

  initial begin
    // BEQ
    check("BEQ equal", 32'h0000_0005, 32'h0000_0005, BRANCH_BEQ, 1'b1, 1'b1);
    check("BEQ not equal", 32'h0000_0005, 32'h0000_0006, BRANCH_BEQ, 1'b1, 1'b0);
    check("BEQ br=0", 32'h0000_0005, 32'h0000_0005, BRANCH_BEQ, 1'b0, 1'b0);

    // BNE
    check("BNE not equal", 32'h0000_0005, 32'h0000_0006, BRANCH_BNE, 1'b1, 1'b1);
    check("BNE equal", 32'h0000_0005, 32'h0000_0005, BRANCH_BNE, 1'b1, 1'b0);

    // BLT (signed)
    check("BLT true", 32'hFFFF_FFFF, 32'h0000_0001, BRANCH_BLT, 1'b1, 1'b1); // -1 < 1
    check("BLT false", 32'h0000_0001, 32'hFFFF_FFFF, BRANCH_BLT, 1'b1, 1'b0); // 1 !< -1
    check("BLT equal", 32'h0000_0005, 32'h0000_0005, BRANCH_BLT, 1'b1, 1'b0);

    // BGE (signed)
    check("BGE greater", 32'h0000_0001, 32'hFFFF_FFFF, BRANCH_BGE, 1'b1, 1'b1); // 1 >= -1
    check("BGE equal", 32'h0000_0005, 32'h0000_0005, BRANCH_BGE, 1'b1, 1'b1);
    check("BGE less", 32'hFFFF_FFFF, 32'h0000_0001, BRANCH_BGE, 1'b1, 1'b0); // -1 !>= 1

    // BLTU (unsigned)
    check("BLTU true", 32'h0000_0001, 32'hFFFF_FFFF, BRANCH_BLTU, 1'b1, 1'b1);
    check("BLTU false", 32'hFFFF_FFFF, 32'h0000_0001, BRANCH_BLTU, 1'b1, 1'b0);
    check("BLTU equal", 32'h0000_0005, 32'h0000_0005, BRANCH_BLTU, 1'b1, 1'b0);

    // BGEU (unsigned)
    check("BGEU greater", 32'hFFFF_FFFF, 32'h0000_0001, BRANCH_BGEU, 1'b1, 1'b1);
    check("BGEU equal", 32'h0000_0005, 32'h0000_0005, BRANCH_BGEU, 1'b1, 1'b1);
    check("BGEU less", 32'h0000_0001, 32'hFFFF_FFFF, BRANCH_BGEU, 1'b1, 1'b0);

    // JAL (unconditional)
    check("JAL taken", 32'h0000_0000, 32'h0000_0000, BRANCH_JAL, 1'b1, 1'b1);
    check("JAL br=0", 32'h0000_0000, 32'h0000_0000, BRANCH_JAL, 1'b0, 1'b0);

    // Edge cases
    check("BLT min/max", 32'h8000_0000, 32'h7FFF_FFFF, BRANCH_BLT, 1'b1, 1'b1); // INT_MIN < INT_MAX
    check("BGE max/min", 32'h7FFF_FFFF, 32'h8000_0000, BRANCH_BGE, 1'b1, 1'b1); // INT_MAX >= INT_MIN

    $display("PASSED: %0d", pass_count_r);
    $display("FAILED: %0d", test_count_r - pass_count_r);

    $finish;
  end

endmodule
