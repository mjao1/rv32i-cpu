module tb_forward_unit import rv32i_pkg::*; ();
  logic [4:0] id_ex_rs1_addr_w;
  logic [4:0] id_ex_rs2_addr_w;
  logic [31:0] id_ex_rs1_data_w;
  logic [31:0] id_ex_rs2_data_w;
  logic ex_mem_reg_write_w;
  logic [4:0] ex_mem_rd_w;
  logic [1:0] ex_mem_result_src_w;
  logic [31:0] ex_mem_alu_res_w;
  logic mem_wb_reg_write_w;
  logic [4:0] mem_wb_rd_w;
  logic [31:0] mem_wb_data_w;
  logic [31:0] rs1_fwd_w;
  logic [31:0] rs2_fwd_w;

  forward_unit u_forward_unit (
    .id_ex_rs1_addr_i (id_ex_rs1_addr_w),
    .id_ex_rs2_addr_i (id_ex_rs2_addr_w),
    .id_ex_rs1_data_i (id_ex_rs1_data_w),
    .id_ex_rs2_data_i (id_ex_rs2_data_w),
    .ex_mem_reg_write_i (ex_mem_reg_write_w),
    .ex_mem_rd_i (ex_mem_rd_w),
    .ex_mem_result_src_i (ex_mem_result_src_w),
    .ex_mem_alu_res_i (ex_mem_alu_res_w),
    .mem_wb_reg_write_i (mem_wb_reg_write_w),
    .mem_wb_rd_i (mem_wb_rd_w),
    .mem_wb_data_i (mem_wb_data_w),
    .rs1_fwd_o (rs1_fwd_w),
    .rs2_fwd_o (rs2_fwd_w)
  );

  int test_count_r = 0;
  int pass_count_r = 0;

  localparam logic [31:0] RS1_REG = 32'hAAAA_AAAA;
  localparam logic [31:0] RS2_REG = 32'hBBBB_BBBB;
  localparam logic [31:0] ALU_VAL = 32'h1111_1111;
  localparam logic [31:0] WB_VAL  = 32'h2222_2222;

  task automatic reset_inputs;
    id_ex_rs1_addr_w    = 5'd1;
    id_ex_rs2_addr_w    = 5'd2;
    id_ex_rs1_data_w    = RS1_REG;
    id_ex_rs2_data_w    = RS2_REG;
    ex_mem_reg_write_w  = 1'b0;
    ex_mem_rd_w         = 5'd0;
    ex_mem_result_src_w = RESULT_ALU;
    ex_mem_alu_res_w    = ALU_VAL;
    mem_wb_reg_write_w  = 1'b0;
    mem_wb_rd_w         = 5'd0;
    mem_wb_data_w       = WB_VAL;
  endtask

  task automatic check(
    input string name,
    input logic [31:0] exp_rs1,
    input logic [31:0] exp_rs2
  );
    #1;
    test_count_r++;
    if (rs1_fwd_w !== exp_rs1) begin
      $display("FAIL: %-25s rs1=0x%08h expected=0x%08h", name, rs1_fwd_w, exp_rs1);
    end else begin
      pass_count_r++;
    end

    test_count_r++;
    if (rs2_fwd_w !== exp_rs2) begin
      $display("FAIL: %-25s rs2=0x%08h expected=0x%08h", name, rs2_fwd_w, exp_rs2);
    end else begin
      pass_count_r++;
    end
  endtask

  initial begin
    // No forwarding
    reset_inputs();
    check("no match", RS1_REG, RS2_REG);

    // EX/MEM forwarding (ALU result)
    reset_inputs();
    ex_mem_reg_write_w = 1'b1;
    ex_mem_rd_w        = 5'd1;
    ex_mem_result_src_w = RESULT_ALU;
    check("ex_mem fwd rs1", ALU_VAL, RS2_REG);

    reset_inputs();
    ex_mem_reg_write_w = 1'b1;
    ex_mem_rd_w        = 5'd2;
    ex_mem_result_src_w = RESULT_ALU;
    check("ex_mem fwd rs2", RS1_REG, ALU_VAL);

    reset_inputs();
    id_ex_rs1_addr_w   = 5'd3;
    id_ex_rs2_addr_w   = 5'd3;
    ex_mem_reg_write_w = 1'b1;
    ex_mem_rd_w        = 5'd3;
    ex_mem_result_src_w = RESULT_ALU;
    check("ex_mem fwd both", ALU_VAL, ALU_VAL);

    reset_inputs();
    ex_mem_reg_write_w  = 1'b1;
    ex_mem_rd_w         = 5'd1;
    ex_mem_result_src_w = RESULT_PC4;
    check("ex_mem fwd PC+4", ALU_VAL, RS2_REG);

    // EX/MEM blocked: load in MEM (RESULT_MEM)
    reset_inputs();
    ex_mem_reg_write_w  = 1'b1;
    ex_mem_rd_w         = 5'd1;
    ex_mem_result_src_w = RESULT_MEM;
    check("ex_mem load no fwd rs1", RS1_REG, RS2_REG);

    reset_inputs();
    ex_mem_reg_write_w  = 1'b1;
    ex_mem_rd_w         = 5'd2;
    ex_mem_result_src_w = RESULT_MEM;
    check("ex_mem load no fwd rs2", RS1_REG, RS2_REG);

    // EX/MEM blocked: rd == x0
    reset_inputs();
    id_ex_rs1_addr_w   = 5'd0;
    id_ex_rs2_addr_w   = 5'd0;
    ex_mem_reg_write_w = 1'b1;
    ex_mem_rd_w        = 5'd0;
    ex_mem_result_src_w = RESULT_ALU;
    check("ex_mem rd=x0 no fwd", RS1_REG, RS2_REG);

    // EX/MEM blocked: reg_write == 0
    reset_inputs();
    ex_mem_reg_write_w = 1'b0;
    ex_mem_rd_w        = 5'd1;
    ex_mem_result_src_w = RESULT_ALU;
    check("ex_mem wen=0 no fwd", RS1_REG, RS2_REG);

    // MEM/WB forwarding
    reset_inputs();
    mem_wb_reg_write_w = 1'b1;
    mem_wb_rd_w        = 5'd1;
    check("mem_wb fwd rs1", WB_VAL, RS2_REG);

    reset_inputs();
    mem_wb_reg_write_w = 1'b1;
    mem_wb_rd_w        = 5'd2;
    check("mem_wb fwd rs2", RS1_REG, WB_VAL);

    reset_inputs();
    id_ex_rs1_addr_w   = 5'd4;
    id_ex_rs2_addr_w   = 5'd4;
    mem_wb_reg_write_w = 1'b1;
    mem_wb_rd_w        = 5'd4;
    check("mem_wb fwd both", WB_VAL, WB_VAL);

    // MEM/WB blocked: rd == x0
    reset_inputs();
    id_ex_rs1_addr_w   = 5'd0;
    mem_wb_reg_write_w = 1'b1;
    mem_wb_rd_w        = 5'd0;
    check("mem_wb rd=x0 no fwd", RS1_REG, RS2_REG);

    // MEM/WB blocked: reg_write == 0
    reset_inputs();
    mem_wb_reg_write_w = 1'b0;
    mem_wb_rd_w        = 5'd1;
    check("mem_wb wen=0 no fwd", RS1_REG, RS2_REG);

    // Priority: EX/MEM wins over MEM/WB
    reset_inputs();
    ex_mem_reg_write_w  = 1'b1;
    ex_mem_rd_w         = 5'd1;
    ex_mem_result_src_w = RESULT_ALU;
    mem_wb_reg_write_w  = 1'b1;
    mem_wb_rd_w         = 5'd1;
    check("priority ex_mem rs1", ALU_VAL, RS2_REG);

    reset_inputs();
    ex_mem_reg_write_w  = 1'b1;
    ex_mem_rd_w         = 5'd2;
    ex_mem_result_src_w = RESULT_ALU;
    mem_wb_reg_write_w  = 1'b1;
    mem_wb_rd_w         = 5'd2;
    check("priority ex_mem rs2", RS1_REG, ALU_VAL);

    // Priority: EX/MEM is load -> MEM/WB wins
    reset_inputs();
    ex_mem_reg_write_w  = 1'b1;
    ex_mem_rd_w         = 5'd1;
    ex_mem_result_src_w = RESULT_MEM;
    mem_wb_reg_write_w  = 1'b1;
    mem_wb_rd_w         = 5'd1;
    check("load ex_mem, mem_wb wins", WB_VAL, RS2_REG);

    // Mixed: rs1 from EX/MEM, rs2 from MEM/WB
    reset_inputs();
    ex_mem_reg_write_w  = 1'b1;
    ex_mem_rd_w         = 5'd1;
    ex_mem_result_src_w = RESULT_ALU;
    mem_wb_reg_write_w  = 1'b1;
    mem_wb_rd_w         = 5'd2;
    check("mixed ex_mem+mem_wb", ALU_VAL, WB_VAL);

    // Mixed: rs1 from MEM/WB, rs2 from EX/MEM
    reset_inputs();
    ex_mem_reg_write_w  = 1'b1;
    ex_mem_rd_w         = 5'd2;
    ex_mem_result_src_w = RESULT_ALU;
    mem_wb_reg_write_w  = 1'b1;
    mem_wb_rd_w         = 5'd1;
    check("mixed mem_wb+ex_mem", WB_VAL, ALU_VAL);

    // No match: different addresses
    reset_inputs();
    id_ex_rs1_addr_w   = 5'd5;
    id_ex_rs2_addr_w   = 5'd6;
    ex_mem_reg_write_w = 1'b1;
    ex_mem_rd_w        = 5'd7;
    ex_mem_result_src_w = RESULT_ALU;
    mem_wb_reg_write_w = 1'b1;
    mem_wb_rd_w        = 5'd8;
    check("no addr match", RS1_REG, RS2_REG);

    $display("PASSED: %0d", pass_count_r);
    $display("FAILED: %0d", test_count_r - pass_count_r);

    $finish;
  end

endmodule
