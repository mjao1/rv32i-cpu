module data_memory #(
  parameter MEM_SIZE = 4096
) (
  input logic clk_i,
  input logic [31:0] addr_i,
  input logic [31:0] write_data_i,
  input logic mem_write_i,
  input logic [2:0] funct3_i,
  output logic [31:0] read_data_o
);

  logic [7:0] mem_r [0:MEM_SIZE-1];

  // Async read with sign/zero extension based on funct3
  always_comb begin
    case (funct3_i)
      3'b000: read_data_o = {{24{mem_r[addr_i][7]}}, mem_r[addr_i]}; // LB
      3'b001: read_data_o = {{16{mem_r[addr_i+1][7]}}, mem_r[addr_i+1], mem_r[addr_i]}; // LH
      3'b010: read_data_o = {mem_r[addr_i+3], mem_r[addr_i+2], mem_r[addr_i+1], mem_r[addr_i]}; // LW
      3'b100: read_data_o = {24'b0, mem_r[addr_i]}; // LBU
      3'b101: read_data_o = {16'b0, mem_r[addr_i+1], mem_r[addr_i]}; // LHU
      default: read_data_o = 32'b0;
    endcase
  end

  // Sync write
  always_ff @(posedge clk_i) begin
    if (mem_write_i) begin
      case (funct3_i)
        3'b000: mem_r[addr_i] <= write_data_i[7:0]; // SB
        3'b001: begin // SH
          mem_r[addr_i] <= write_data_i[7:0];
          mem_r[addr_i+1] <= write_data_i[15:8];
        end
        3'b010: begin // SW
          mem_r[addr_i] <= write_data_i[7:0];
          mem_r[addr_i+1] <= write_data_i[15:8];
          mem_r[addr_i+2] <= write_data_i[23:16];
          mem_r[addr_i+3] <= write_data_i[31:24];
        end
        default: ;
      endcase
    end
  end

endmodule
