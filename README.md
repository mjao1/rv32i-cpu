# rv32i-cpu

## Project Overview

A synthesizable single-cycle RISC-V RV32I processor in SystemVerilog, aimed at ASIC-style flows with simulation using Icarus Verilog. The core implements the RV32I base integer ISA: ALU ops, loads/stores, branches, jumps, LUI/AUIPC, and JAL/JALR. Instruction memory is loaded via a testbench write port or `$readmemh`, data memory is byte-addressable RAM with a configurable base address for bare-metal programs.

## Architecture Overview

- **Single-cycle datapath:** One instruction completes per clock (fetch -> decode -> execute -> memory -> writeback in one cycle).
- **PC:** Registered; next PC is sequential (`PC+4`) or branch/jump target from the ALU/branch logic.
- **Register file:** 32 × 32-bit, dual read, one write; x0 always reads as 0.
- **ALU:** Add/sub, shifts, compares, bitwise ops; shared for addresses and branch targets.
- **Memories:** Separate instruction memory (word oriented with byte-addressed load path) and data memory (little endian byte access).

## Project Structure

```
rv32i-cpu/             
├── rtl/
│   ├── alu.sv
│   ├── branch_unit.sv
│   ├── data_memory.sv
│   ├── decoder.sv
│   ├── immediate_generator.sv
│   ├── instruction_memory.sv
│   ├── register_file.sv
│   ├── rv32i_cpu.sv           # CPU top-level
|   └── rv32i_pkg.sv           # Shared types (alu_op_t, branch_op_t, result_src_t)
├── sim/
│   ├── tb_rv32i_cpu.sv        # Hand encoded instruction smoke test
│   ├── tb_rv32i_cpu_c.sv      # C program loaded from memory image
│   └── tb_*.sv                # Unit testbenches
└── test/
    ├── programs/              # *.mem / *.hex images for simulation
    └── software/              # Bare metal C, linker script, Makefile
```

## RTL Implementation

### CPU and datapath

- **rv32i_cpu:** Top level; PC register, instruction fetch, decode, register file, immediate generation, ALU, branch unit, data memory interface, result mux (ALU / PC+4 / load data), and next-PC selection.
- **decoder:** Decodes RV32I opcode/funct fields into ALU operation, source selects, reg write, mem write, branch type, and register addresses.
- **alu:** Combinational ALU (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`, `SLTU`, `SLL`, `SRL`, `SRA`).
- **register_file:** 32 registers; asynchronous read, synchronous write; x0 write discarded.
- **immediate_generator:** Builds sign-extended immediates for I/S/B/U/J formats.
- **branch_unit:** Branch condition evaluation from `funct3` and comparison inputs.

### Memories

- **instruction_memory:** Parameterized word array; asynchronous read by word address; synchronous write for testbench loading.
- **data_memory:** Byte-addressable RAM with synchronous write and combinational read (aligned to the CPU’s load/store path).

### Package

- **rv32i_pkg:** Opcode constants, `alu_op_t`, `branch_op_t`, `result_src_t`.

## Simulation

Run commands from the **repository root**. Outputs `sim/tb_*.vvp` are regenerated each compile.

### Top-level smoke test (hand encoded program)

```bash
iverilog -g2012 -o sim/tb_rv32i_cpu.vvp rtl/rv32i_pkg.sv sim/tb_rv32i_cpu.sv rtl/a*.sv rtl/b*.sv rtl/d*.sv rtl/i*.sv rtl/register_file.sv rtl/rv32i_cpu.sv && vvp sim/tb_rv32i_cpu.vvp
```

### Top-level test with compiled C (`test/programs/main.mem`)

Build the bare-metal image first, then simulate:

```bash
cd test/software && make && cd ../..
iverilog -g2012 -o sim/tb_rv32i_cpu_c.vvp rtl/rv32i_pkg.sv sim/tb_rv32i_cpu_c.sv rtl/a*.sv rtl/b*.sv rtl/d*.sv rtl/i*.sv rtl/register_file.sv rtl/rv32i_cpu.sv && vvp sim/tb_rv32i_cpu_c.vvp
```

The C testbench checks return value in **a0 (x10)** against `expected_value` in `sim/tb_rv32i_cpu_c.sv` (adjust if you change `main.c`).

**Toolchain:** `riscv64-unknown-elf-gcc` with `-march=rv32i -mabi=ilp32` (see `test/software/Makefile`). 

**Link map:** `.text` at `0x00000000`, RAM/stack at `0x80000000`, matching `DMEM_BASE` on `rv32i_cpu` in that testbench.

### Individual module tests

```bash
# ALU
iverilog -g2012 -o sim/tb_alu.vvp rtl/rv32i_pkg.sv rtl/alu.sv sim/tb_alu.sv && vvp sim/tb_alu.vvp

# Register file
iverilog -g2012 -o sim/tb_register_file.vvp rtl/rv32i_pkg.sv rtl/register_file.sv sim/tb_register_file.sv && vvp sim/tb_register_file.vvp

# Immediate generator
iverilog -g2012 -o sim/tb_immediate_generator.vvp rtl/rv32i_pkg.sv rtl/immediate_generator.sv sim/tb_immediate_generator.sv && vvp sim/tb_immediate_generator.vvp

# Branch unit
iverilog -g2012 -o sim/tb_branch_unit.vvp rtl/rv32i_pkg.sv rtl/branch_unit.sv sim/tb_branch_unit.sv && vvp sim/tb_branch_unit.vvp

# Decoder
iverilog -g2012 -o sim/tb_decoder.vvp rtl/rv32i_pkg.sv rtl/decoder.sv sim/tb_decoder.sv && vvp sim/tb_decoder.vvp

# Instruction memory
iverilog -g2012 -o sim/tb_instruction_memory.vvp rtl/instruction_memory.sv sim/tb_instruction_memory.sv && vvp sim/tb_instruction_memory.vvp

# Data memory
iverilog -g2012 -o sim/tb_data_memory.vvp rtl/data_memory.sv sim/tb_data_memory.sv && vvp sim/tb_data_memory.vvp
```
