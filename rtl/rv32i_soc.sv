// SoC style top: rv32i_cpu (EXT_DMEM) + AXI-Lite LSU + axi_lite_interconnect (DMEM, GPIO, UART, TIMER)
module rv32i_soc #(
  parameter int IMEM_SIZE = 1024,
  parameter int DMEM_BYTES = 4096,
  parameter logic [31:0] DMEM_BASE = 32'h0000_0000,
  parameter logic [31:0] GPIO_BASE = 32'h1000_0000,
  parameter int GPIO_BYTES = 4096,
  parameter logic [31:0] UART_BASE = 32'h1000_1000,
  parameter int UART_BYTES = 4096,
  parameter logic [31:0] TIMER_BASE = 32'h1000_2000,
  parameter int TIMER_BYTES = 4096
) (
  input logic clk_i,
  input logic rst_i,

  input logic imem_write_en_i,
  input logic [31:0] imem_write_addr_i,
  input logic [31:0] imem_write_data_i,

  input logic [31:0] gpio_i,
  output logic [31:0] gpio_o,

  input logic uart_rx_i,
  output logic uart_tx_o,

  output logic [31:0] dbg_pc_o
);

  logic lsu_stall_w;
  logic lsu_load_rsp_w;
  logic [4:0] lsu_load_rd_w;
  logic [31:0] lsu_load_data_w;

  logic [31:0] ex_mem_addr_w;
  logic [4:0] ex_mem_rd_w;
  logic ex_mem_mem_write_w;
  logic ex_mem_reg_write_w;
  logic [1:0] ex_mem_result_src_w;
  logic [2:0] ex_mem_funct3_w;
  logic [31:0] ex_mem_wdata_w;

  logic [31:0] m_axi_araddr;
  logic [2:0] m_axi_arprot;
  logic m_axi_arvalid;
  logic m_axi_arready;
  logic [31:0] m_axi_rdata;
  logic [1:0] m_axi_rresp;
  logic m_axi_rvalid;
  logic m_axi_rready;
  logic [31:0] m_axi_awaddr;
  logic [2:0] m_axi_awprot;
  logic m_axi_awvalid;
  logic m_axi_awready;
  logic [31:0] m_axi_wdata;
  logic [3:0] m_axi_wstrb;
  logic m_axi_wvalid;
  logic m_axi_wready;
  logic [1:0] m_axi_bresp;
  logic m_axi_bvalid;
  logic m_axi_bready;

  rv32i_cpu #(
    .IMEM_SIZE (IMEM_SIZE),
    .DMEM_SIZE (DMEM_BYTES),
    .DMEM_BASE (DMEM_BASE),
    .EXT_DMEM (1'b1)
  ) u_cpu (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .imem_write_en_i (imem_write_en_i),
    .imem_write_addr_i (imem_write_addr_i),
    .imem_write_data_i (imem_write_data_i),
    .dmem_stall_i (lsu_stall_w),
    .dmem_rsp_valid_i (lsu_load_rsp_w),
    .dmem_load_rd_i (lsu_load_rd_w),
    .dmem_rdata_i (lsu_load_data_w),
    .ex_mem_alu_res_o (ex_mem_addr_w),
    .ex_mem_mem_write_o (ex_mem_mem_write_w),
    .ex_mem_reg_write_o (ex_mem_reg_write_w),
    .ex_mem_result_src_o (ex_mem_result_src_w),
    .ex_mem_funct3_o (ex_mem_funct3_w),
    .ex_mem_rs2_o (ex_mem_wdata_w),
    .ex_mem_rd_addr_o (ex_mem_rd_w)
  );

  assign dbg_pc_o = u_cpu.pc_r;

  dmem_axi_lite_master u_lsu (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .ex_mem_addr_i (ex_mem_addr_w),
    .ex_mem_mem_write_i (ex_mem_mem_write_w),
    .ex_mem_reg_write_i (ex_mem_reg_write_w),
    .ex_mem_result_src_i (ex_mem_result_src_w),
    .ex_mem_funct3_i (ex_mem_funct3_w),
    .ex_mem_wdata_i (ex_mem_wdata_w),
    .ex_mem_rd_i (ex_mem_rd_w),
    .stall_o (lsu_stall_w),
    .load_rsp_valid_o (lsu_load_rsp_w),
    .load_rd_o (lsu_load_rd_w),
    .load_data_o (lsu_load_data_w),
    .m_axi_araddr (m_axi_araddr),
    .m_axi_arprot (m_axi_arprot),
    .m_axi_arvalid (m_axi_arvalid),
    .m_axi_arready (m_axi_arready),
    .m_axi_rdata (m_axi_rdata),
    .m_axi_rresp (m_axi_rresp),
    .m_axi_rvalid (m_axi_rvalid),
    .m_axi_rready (m_axi_rready),
    .m_axi_awaddr (m_axi_awaddr),
    .m_axi_awprot (m_axi_awprot),
    .m_axi_awvalid (m_axi_awvalid),
    .m_axi_awready (m_axi_awready),
    .m_axi_wdata (m_axi_wdata),
    .m_axi_wstrb (m_axi_wstrb),
    .m_axi_wvalid (m_axi_wvalid),
    .m_axi_wready (m_axi_wready),
    .m_axi_bresp (m_axi_bresp),
    .m_axi_bvalid (m_axi_bvalid),
    .m_axi_bready (m_axi_bready)
  );

  axi_lite_interconnect #(
    .DMEM_BASE (DMEM_BASE),
    .DMEM_BYTES (DMEM_BYTES),
    .GPIO_BASE (GPIO_BASE),
    .GPIO_BYTES (GPIO_BYTES),
    .UART_BASE (UART_BASE),
    .UART_BYTES (UART_BYTES),
    .TIMER_BASE (TIMER_BASE),
    .TIMER_BYTES (TIMER_BYTES)
  ) u_ic (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .uart_rx_i (uart_rx_i),
    .uart_tx_o (uart_tx_o),
    .m_axi_awaddr (m_axi_awaddr),
    .m_axi_awprot (m_axi_awprot),
    .m_axi_awvalid (m_axi_awvalid),
    .m_axi_awready (m_axi_awready),
    .m_axi_wdata (m_axi_wdata),
    .m_axi_wstrb (m_axi_wstrb),
    .m_axi_wvalid (m_axi_wvalid),
    .m_axi_wready (m_axi_wready),
    .m_axi_bresp (m_axi_bresp),
    .m_axi_bvalid (m_axi_bvalid),
    .m_axi_bready (m_axi_bready),
    .m_axi_araddr (m_axi_araddr),
    .m_axi_arprot (m_axi_arprot),
    .m_axi_arvalid (m_axi_arvalid),
    .m_axi_arready (m_axi_arready),
    .m_axi_rdata (m_axi_rdata),
    .m_axi_rresp (m_axi_rresp),
    .m_axi_rvalid (m_axi_rvalid),
    .m_axi_rready (m_axi_rready)
  );

endmodule
