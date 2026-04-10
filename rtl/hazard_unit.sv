module hazard_unit import rv32i_pkg::*; (
  input logic [4:0] id_ex_rs1_i,
  input logic [4:0] id_ex_rs2_i,
  input logic ex_mem_reg_write_i,
  input result_src_t ex_mem_result_src_i,
  input logic [4:0] ex_mem_rd_i,
  output logic stall_if_o
);

  assign stall_if_o = ex_mem_reg_write_i && (ex_mem_result_src_i == RESULT_MEM) && (ex_mem_rd_i != 5'b0) && (((ex_mem_rd_i == id_ex_rs1_i) && (id_ex_rs1_i != 5'b0)) || ((ex_mem_rd_i == id_ex_rs2_i) && (id_ex_rs2_i != 5'b0)));

endmodule
