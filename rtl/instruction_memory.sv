module instruction_memory #(
  parameter MEM_SIZE = 1024
) (
  input logic clk_i,
  input logic write_en_i,
  input logic [31:0] write_addr_i,
  input logic [31:0] write_data_i,
  input logic [31:0] addr_i,
  output logic [31:0] instruction_o
);

  logic [31:0] mem_r [0:MEM_SIZE-1];

  // Async read
  assign instruction_o = mem_r[addr_i >> 2];

  // Sync write
  always_ff @(posedge clk_i) begin
    if (write_en_i)
      mem_r[write_addr_i >> 2] <= write_data_i;
  end

endmodule
