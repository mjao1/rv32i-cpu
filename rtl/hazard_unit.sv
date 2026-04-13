module hazard_unit (
  input logic [4:0] if_id_rs1_i,
  input logic [4:0] if_id_rs2_i,
  input logic id_ex_reg_write_i,
  input logic [1:0] id_ex_result_src_i,
  input logic [4:0] id_ex_rd_i,
  output logic stall_if_o
);

  assign stall_if_o = id_ex_reg_write_i && (id_ex_result_src_i == rv32i_pkg::RESULT_MEM) && (id_ex_rd_i != 5'b0) && (((id_ex_rd_i == if_id_rs1_i) && (if_id_rs1_i != 5'b0)) || ((id_ex_rd_i == if_id_rs2_i) && (if_id_rs2_i != 5'b0)));

endmodule
