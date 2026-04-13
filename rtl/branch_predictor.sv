module branch_predictor (
  input  logic [31:0] instruction_i,
  input  logic [31:0] pc_i,
  output logic predict_taken_o,
  output logic [31:0] predicted_target_o
);

  logic is_branch_w;
  logic [31:0] b_imm_w;

  assign is_branch_w = (instruction_i[6:0] == rv32i_pkg::OP_BRANCH);

  // B-type immediate extraction (sign extended)
  assign b_imm_w = {{19{instruction_i[31]}}, instruction_i[31], instruction_i[7], instruction_i[30:25], instruction_i[11:8], 1'b0};

  // BTFNT
  assign predict_taken_o = is_branch_w & instruction_i[31];
  assign predicted_target_o = pc_i + b_imm_w;

endmodule
