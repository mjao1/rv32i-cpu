module immediate_generator import rv32i_pkg::*; (
  input logic [31:0] instruction_i,
  output logic [31:0] immediate_o
);

  logic [6:0] opcode_w;
  assign opcode_w = instruction_i[6:0];

  always_comb begin
    case (opcode_w)
      // I-type: loads, ALU immediate, JALR
      OP_LOAD, OP_ALU_I, OP_JALR: immediate_o = {{20{instruction_i[31]}}, instruction_i[31:20]};

      // S-type: stores
      OP_STORE: immediate_o = {{20{instruction_i[31]}}, instruction_i[31:25], instruction_i[11:7]};

      // B-type: branches
      OP_BRANCH: immediate_o = {{19{instruction_i[31]}}, instruction_i[31], instruction_i[7], instruction_i[30:25], instruction_i[11:8], 1'b0};

      // U-type: LUI, AUIPC
      OP_LUI, OP_AUIPC: immediate_o = {instruction_i[31:12], 12'b0};

      // J-type: JAL
      OP_JAL: immediate_o = {{11{instruction_i[31]}}, instruction_i[31], instruction_i[19:12], instruction_i[20], instruction_i[30:21], 1'b0};

      default: immediate_o = 32'b0;
    endcase
  end

endmodule
