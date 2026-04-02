module instruction_memory #(
  parameter MEM_SIZE = 1024,
  parameter MEM_INIT = ""
) (
  input logic [31:0] addr_i,
  output logic [31:0] instruction_o
);

  logic [31:0] mem_r [0:MEM_SIZE-1];

  // not synthesizable!
  initial begin
    if (MEM_INIT != "")
      $readmemh(MEM_INIT, mem_r);
  end

  assign instruction_o = mem_r[addr_i >> 2];

endmodule
