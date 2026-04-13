module tb_hazard_unit import rv32i_pkg::*; ();
  logic [4:0] if_id_rs1_w;
  logic [4:0] if_id_rs2_w;
  logic id_ex_reg_write_w;
  logic [1:0] id_ex_result_src_w;
  logic [4:0] id_ex_rd_w;
  logic stall_w;

  hazard_unit u_hazard_unit (
    .if_id_rs1_i (if_id_rs1_w),
    .if_id_rs2_i (if_id_rs2_w),
    .id_ex_reg_write_i (id_ex_reg_write_w),
    .id_ex_result_src_i (id_ex_result_src_w),
    .id_ex_rd_i (id_ex_rd_w),
    .stall_if_o (stall_w)
  );

  int test_count_r = 0;
  int pass_count_r = 0;

  task automatic reset_inputs;
    if_id_rs1_w         = 5'd0;
    if_id_rs2_w         = 5'd0;
    id_ex_reg_write_w   = 1'b0;
    id_ex_result_src_w  = RESULT_ALU;
    id_ex_rd_w          = 5'd0;
  endtask

  task automatic check(
    input string name,
    input logic expected_stall
  );
    #1;
    test_count_r++;
    if (stall_w === expected_stall) begin
      pass_count_r++;
    end else begin
      $display("FAIL: %-25s stall=%0b expected=%0b", name, stall_w, expected_stall);
    end
  endtask

  initial begin
    // Load-use hazard: should stall
    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_MEM;
    id_ex_rd_w         = 5'd3;
    if_id_rs1_w        = 5'd3;
    if_id_rs2_w        = 5'd0;
    check("load match rs1", 1'b1);

    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_MEM;
    id_ex_rd_w         = 5'd4;
    if_id_rs1_w        = 5'd0;
    if_id_rs2_w        = 5'd4;
    check("load match rs2", 1'b1);

    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_MEM;
    id_ex_rd_w         = 5'd5;
    if_id_rs1_w        = 5'd5;
    if_id_rs2_w        = 5'd5;
    check("load match both", 1'b1);

    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_MEM;
    id_ex_rd_w         = 5'd31;
    if_id_rs1_w        = 5'd31;
    if_id_rs2_w        = 5'd0;
    check("load match x31", 1'b1);

    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_MEM;
    id_ex_rd_w         = 5'd6;
    if_id_rs1_w        = 5'd6;
    if_id_rs2_w        = 5'd7;
    check("load match rs1 only", 1'b1);

    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_MEM;
    id_ex_rd_w         = 5'd7;
    if_id_rs1_w        = 5'd6;
    if_id_rs2_w        = 5'd7;
    check("load match rs2 only", 1'b1);

    // Non-load in MEM: no stall
    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_ALU;
    id_ex_rd_w         = 5'd3;
    if_id_rs1_w        = 5'd3;
    check("ALU no stall", 1'b0);

    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_PC4;
    id_ex_rd_w         = 5'd3;
    if_id_rs1_w        = 5'd3;
    check("PC+4 no stall", 1'b0);

    // rd == x0: no stall
    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_MEM;
    id_ex_rd_w         = 5'd0;
    if_id_rs1_w        = 5'd0;
    if_id_rs2_w        = 5'd0;
    check("load rd=x0", 1'b0);

    // rs == x0: no stall
    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_MEM;
    id_ex_rd_w         = 5'd3;
    if_id_rs1_w        = 5'd0;
    if_id_rs2_w        = 5'd0;
    check("rs1=rs2=x0", 1'b0);

    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_MEM;
    id_ex_rd_w         = 5'd0;
    if_id_rs1_w        = 5'd3;
    if_id_rs2_w        = 5'd4;
    check("rd=x0 rs nonzero", 1'b0);

    // reg_write == 0: no stall
    reset_inputs();
    id_ex_reg_write_w  = 1'b0;
    id_ex_result_src_w = RESULT_MEM;
    id_ex_rd_w         = 5'd3;
    if_id_rs1_w        = 5'd3;
    check("wen=0 no stall", 1'b0);

    // No address match: no stall
    reset_inputs();
    id_ex_reg_write_w  = 1'b1;
    id_ex_result_src_w = RESULT_MEM;
    id_ex_rd_w         = 5'd3;
    if_id_rs1_w        = 5'd4;
    if_id_rs2_w        = 5'd5;
    check("no addr match", 1'b0);

    // Idle: no stall
    reset_inputs();
    check("idle", 1'b0);

    $display("PASSED: %0d", pass_count_r);
    $display("FAILED: %0d", test_count_r - pass_count_r);

    $finish;
  end

endmodule
