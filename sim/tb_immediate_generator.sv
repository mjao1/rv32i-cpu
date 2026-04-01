module tb_immediate_generator import rv32i_pkg::*; ();
  logic [31:0] instruction_w;
  logic [31:0] immediate_w;

  immediate_generator u_immediate_generator (
    .instruction_i (instruction_w),
    .immediate_o (immediate_w)
  );

  int test_count_r = 0;
  int pass_count_r = 0;

  task automatic check(
    input string name,
    input logic [31:0] instr,
    input logic [31:0] expected
  );
    instruction_w = instr;
    #1;

    test_count_r++;
    if (immediate_w === expected) begin
      pass_count_r++;
    end else begin
      $display("FAIL: %-20s instr=0x%08h got=0x%08h expected=0x%08h", name, instr, immediate_w, expected);
    end
  endtask

  initial begin
    // I-type
    // imm[11:0], rs1[4:0], funct3[2:0], rd[4:0], opcode[6:0]
    // ADDI x1, x0, 5, imm=0x005
    check("I pos imm", 32'b0000_0000_0101_00000_000_00001_0010011, 32'h0000_0005);

    // ADDI x1, x0, -1, imm=0xFFF
    check("I neg imm", 32'b1111_1111_1111_00000_000_00001_0010011, 32'hFFFF_FFFF);

    // ADDI x1, x0, 2047, imm=0x7FF
    check("I max pos", 32'b0111_1111_1111_00000_000_00001_0010011, 32'h0000_07FF);

    // ADDI x1, x0, -2048, imm=0x800
    check("I min neg", 32'b1000_0000_0000_00000_000_00001_0010011, 32'hFFFF_F800);

    // LW x1, 4(x2), imm=4
    check("I load", 32'b0000_0000_0100_00010_010_00001_0000011, 32'h0000_0004);

    // JALR x1, x2, 8
    check("I jalr", 32'b0000_0000_1000_00010_000_00001_1100111, 32'h0000_0008);

    // S-type
    // imm[11:5], rs2[4:0], rs1[4:0], funct3[2:0], imm[4:0], opcode[6:0]
    // SW x1, 8(x2), imm=0x008
    check("S pos imm", 32'b0000000_00001_00010_010_01000_0100011, 32'h0000_0008);

    // SW x1, -4(x2), imm=0xFFC
    check("S neg imm", 32'b1111111_00001_00010_010_11100_0100011, 32'hFFFF_FFFC);

    // B-type
    // imm[12], imm[10:5], rs2[4:0], rs1[4:0], funct3[2:0], imm[4:1], imm[11], opcode[6:0]
    // BEQ x1, x2, +8, imm=0x008
    check("B pos imm", 32'b0_000000_00010_00001_000_0100_0_1100011, 32'h0000_0008);

    // BEQ x1, x2, -8, imm=-8
    check("B neg imm", 32'b1_111111_00010_00001_000_1100_1_1100011, 32'hFFFF_FFF8);

    // U-type
    // imm[31:12], rd[4:0], opcode[6:0]
    // LUI x1, 0xABCDE, imm=0xABCDE
    check("U lui", 32'hABCDE_037, 32'hABCDE_000);

    // AUIPC x1, 0x12345, opcode=0010111
    check("U auipc", 32'h12345_097, 32'h12345_000);

    // J-type
    // imm[20], imm[10:1], imm[11], imm[19:12], rd[4:0], opcode[6:0]
    // JAL x1, +8
    check("J pos imm", 32'b0_0000000100_0_00000000_00001_1101111, 32'h0000_0008);

    // JAL x1, -20
    check("J neg imm", 32'b1_1111110110_1_11111111_00001_1101111, 32'hFFFF_FFEC);

    // R-type
    // funct7[6:0], rs2[4:0], rs1[4:0], funct3[2:0], rd[4:0], opcode[6:0]
    // ADD x1, x2, x3, imm=0x000
    check("R default 0", 32'b0000000_00011_00010_000_00001_0110011, 32'h0000_0000);

    $display("PASSED: %0d", pass_count_r);
    $display("FAILED: %0d", test_count_r - pass_count_r);

    $finish;
  end

endmodule
