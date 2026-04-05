module rv32i_cpu import rv32i_pkg::*; #(
  parameter IMEM_SIZE = 1024,
  parameter DMEM_SIZE = 4096,
  parameter logic [31:0] DMEM_BASE = 32'h0000_0000
) (
  input logic clk_i,
  input logic rst_i,
  input logic imem_write_en_i,
  input logic [31:0] imem_write_addr_i,
  input logic [31:0] imem_write_data_i
);

  // PC
  logic [31:0] pc_r;
  logic [31:0] pc_next_w;
  logic [31:0] pc_plus4_w;

  assign pc_plus4_w = pc_r + 32'd4;

  always_ff @(posedge clk_i) begin
    if (rst_i)
      pc_r <= 32'b0;
    else
      pc_r <= pc_next_w;
  end

  // Next PC (clear bit 0 for JALR)
  assign pc_next_w = branch_taken_w ? {alu_result_w[31:1], 1'b0} : pc_plus4_w;

  // Instruction fetch
  logic [31:0] instruction_w;

  instruction_memory #(
    .MEM_SIZE (IMEM_SIZE)
  ) u_instruction_memory (
    .clk_i (clk_i),
    .write_en_i (imem_write_en_i),
    .write_addr_i (imem_write_addr_i),
    .write_data_i (imem_write_data_i),
    .addr_i (pc_r),
    .instruction_o (instruction_w)
  );

  // Decode
  alu_op_t alu_op_w;
  logic alu_src_a_w;
  logic alu_src_b_w;
  logic reg_write_w;
  logic mem_write_w;
  result_src_t result_src_w;
  logic branch_w;
  branch_op_t branch_op_w;
  logic [4:0] rs1_addr_w;
  logic [4:0] rs2_addr_w;
  logic [4:0] rd_addr_w;
  logic [2:0] funct3_w;

  decoder u_decoder (
    .instruction_i (instruction_w),
    .alu_op_o (alu_op_w),
    .alu_src_a_o (alu_src_a_w),
    .alu_src_b_o (alu_src_b_w),
    .reg_write_o (reg_write_w),
    .mem_write_o (mem_write_w),
    .result_src_o (result_src_w),
    .branch_o (branch_w),
    .branch_op_o (branch_op_w),
    .rs1_addr_o (rs1_addr_w),
    .rs2_addr_o (rs2_addr_w),
    .rd_addr_o (rd_addr_w),
    .funct3_o (funct3_w)
  );

  // Immediate generator
  logic [31:0] immediate_w;

  immediate_generator u_immediate_generator (
    .instruction_i (instruction_w),
    .immediate_o (immediate_w)
  );

  // Register file
  logic [31:0] rs1_data_w;
  logic [31:0] rs2_data_w;
  logic [31:0] rd_data_w;

  register_file u_register_file (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .rs1_addr_i (rs1_addr_w),
    .rs2_addr_i (rs2_addr_w),
    .rd_addr_i (rd_addr_w),
    .rd_data_i (rd_data_w),
    .reg_write_i (reg_write_w),
    .rs1_data_o (rs1_data_w),
    .rs2_data_o (rs2_data_w)
  );

  // ALU source muxes
  logic [31:0] alu_operand_a_w;
  logic [31:0] alu_operand_b_w;

  assign alu_operand_a_w = alu_src_a_w ? pc_r : rs1_data_w;
  assign alu_operand_b_w = alu_src_b_w ? immediate_w : rs2_data_w;

  // ALU
  logic [31:0] alu_result_w;

  alu u_alu (
    .operand_a_i (alu_operand_a_w),
    .operand_b_i (alu_operand_b_w),
    .alu_op_i (alu_op_w),
    .alu_result_o (alu_result_w)
  );

  // Branch unit
  logic branch_taken_w;

  branch_unit u_branch_unit (
    .rs1_data_i (rs1_data_w),
    .rs2_data_i (rs2_data_w),
    .branch_op_i (branch_op_w),
    .branch_i (branch_w),
    .branch_taken_o (branch_taken_w)
  );

  // Data memory
  logic [31:0] mem_read_data_w;

  data_memory #(
    .MEM_SIZE (DMEM_SIZE),
    .DMEM_BASE (DMEM_BASE)
  ) u_data_memory (
    .clk_i (clk_i),
    .addr_i (alu_result_w),
    .write_data_i (rs2_data_w),
    .mem_write_i (mem_write_w),
    .funct3_i (funct3_w),
    .read_data_o (mem_read_data_w)
  );

  // Result mux to register file write data
  always_comb begin
    case (result_src_w)
      RESULT_ALU: rd_data_w = alu_result_w;
      RESULT_PC4: rd_data_w = pc_plus4_w;
      RESULT_MEM: rd_data_w = mem_read_data_w;
      default: rd_data_w = alu_result_w;
    endcase
  end

endmodule
