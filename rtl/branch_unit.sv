module branch_unit import rv32i_pkg::*; (
  input logic [31:0] rs1_data_i,
  input logic [31:0] rs2_data_i,
  input branch_op_t branch_op_i,
  input logic branch_i,
  output logic branch_taken_o
);

  logic condition_met_w;

  always_comb begin
    case (branch_op_i)
      BRANCH_BEQ:  condition_met_w = (rs1_data_i == rs2_data_i);
      BRANCH_BNE:  condition_met_w = (rs1_data_i != rs2_data_i);
      BRANCH_BLT:  condition_met_w = ($signed(rs1_data_i) < $signed(rs2_data_i));
      BRANCH_BGE:  condition_met_w = ($signed(rs1_data_i) >= $signed(rs2_data_i));
      BRANCH_BLTU: condition_met_w = (rs1_data_i < rs2_data_i);
      BRANCH_BGEU: condition_met_w = (rs1_data_i >= rs2_data_i);
      BRANCH_JAL:  condition_met_w = 1'b1;
      default:     condition_met_w = 1'b0;
    endcase
  end

  assign branch_taken_o = branch_i & condition_met_w;

endmodule
