# Single-Cycle 32-Bit RISC-V (RV32I) Processor in Verilog HDL

![Verilog HDL](https://img.shields.io/badge/HDL-Verilog-blue.svg)
![ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32I-green.svg)
![Instructions](https://img.shields.io/badge/RV32I%20Base-37%2F37%20Instructions-brightgreen.svg)
![EDA Tools](https://img.shields.io/badge/EDA-Quartus%20Prime%20%7C%20ModelSim-orange.svg)

A modular, latch-free **Single-Cycle 32-Bit RISC-V (`RV32I`) Processor Core** designed in synthesizable Verilog HDL for the **Complex Engineering Problem (CEP)** in **(TC-205) Digital Logic Design** at **NED University of Engineering & Technology, Karachi**.

The processor executes the complete unprivileged base integer instruction set (**all 37 RV32I instructions** across R, I, S, B, U, and J formats) within a single clock cycle and is verified through nine self-checking unit testbenches alongside an end-to-end 63-instruction assembly verification suite.

---

## Table of Contents

- [Architectural Highlights](#architectural-highlights)
- [Supported RV32I Instruction Set](#supported-rv32i-instruction-set)
- [RTL Module Hierarchy](#rtl-module-hierarchy)
- [Repository Structure](#repository-structure)
- [ModelSim Simulation and Verification](#modelsim-simulation-and-verification)
- [Quartus Prime Synthesis](#quartus-prime-synthesis)
- [Project Team](#project-team)
- [References](#references)

---

## Architectural Highlights

- **Single-Cycle Harvard Architecture:** Separate `256 × 32-bit` (1 KB) word-aligned Instruction ROM (`instr_mem.v`) and `256 × 32-bit` (1 KB) little-endian Data RAM (`data_mem.v`) enable simultaneous instruction fetch and memory load/store within a single clock cycle without structural hazards.
- **Complete 37-Instruction RV32I Coverage:** Implements register and immediate arithmetic, bitwise logic, logical/arithmetic shifts, signed/unsigned comparisons, upper immediates, byte/halfword/word memory operations, all six conditional branches, and direct/indirect jumps.
- **Strict RISC-V ISA Compliance:**
  - **Hardwired Zero Register (`x0`):** Reads from `x0` always return `32'h0000_0000`, and synchronous writes targeting `rd == 5'd0` are blocked.
  - **`JALR` Target Alignment:** Clears the least-significant bit of the computed jump target (`{alu_result[31:1], 1'b0}`) per the RISC-V specification.
  - **Isolated Secondary ALU Decoding:** Inspects `instr[30]` strictly for R-type `SUB` and R/I-type `SRA`/`SRAI`, ensuring immediate bit `30` in `ADDI` never triggers unintended subtraction.
- **100% Latch-Free RTL Design:** All combinational `always @(*)` blocks initialize outputs up front, and all sequential `always @(posedge clk)` blocks use non-blocking assignments (`<=`).

---

## Supported RV32I Instruction Set

| Format | Supported Mnemonics | Count | Architectural Operation |
| :--- | :--- | :---: | :--- |
| **R-Type** | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` | 10 | Register-to-register arithmetic, shifts, signed/unsigned comparisons, and bitwise logic |
| **I-Type (ALU)** | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` | 9 | Register-immediate arithmetic, shifts, signed/unsigned comparisons, and bitwise logic |
| **I-Type (Load)** | `LB`, `LH`, `LW`, `LBU`, `LHU` | 5 | Little-endian byte, halfword, and word loads with sign or zero extension |
| **S-Type (Store)** | `SB`, `SH`, `SW` | 3 | Little-endian byte-lane, halfword, and word stores |
| **B-Type (Branch)** | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | 6 | PC-relative conditional branches evaluated via `zero`, signed `lt`, and unsigned `ltu` flags |
| **U-Type** | `LUI`, `AUIPC` | 2 | Load 20-bit upper immediate (`imm << 12`) and add upper immediate to `PC` |
| **J-Type & Jump** | `JAL`, `JALR` | 2 | Unconditional direct and register-indirect jumps saving `PC + 4` into `rd` |
| **System / Fence** | `FENCE`, `ECALL`, `EBREAK` | — | Safely decoded as latch-free `NOP` cycles |

---

## RTL Module Hierarchy

| File | Module | Hardware Role & Storage | Primary Interface Ports |
| :--- | :--- | :--- | :--- |
| `rtl/core_top.v` | `core_top` | Top-level structural integration, secondary `alu_ctrl` decoder, 6-condition branch unit, 3-way `pc_next` mux, and 3-way write-back mux | `clk, rst` |
| `rtl/pc.v` | `pc` | 32-bit Program Counter flip-flop register with active-high asynchronous reset (`0x0000_0000`) | `clk, rst, pc_next → pc_current` |
| `rtl/instr_mem.v` | `instr_mem` | `256 × 32-bit` (1 KB) combinational Instruction ROM indexed via `pc[31:2]`, pre-filled with `NOP` and loaded via `$readmemh` | `pc → instr` |
| `rtl/reg_file.v` | `reg_file` | `32 × 32-bit` register bank (`x0`–`x31`), dual asynchronous read ports, synchronous write port, hardwired `x0 = 0` | `clk, reg_write, rs1, rs2, rd, rd_data → rs1_data, rs2_data` |
| `rtl/alu.v` | `alu` | 11-operation 32-bit combinational ALU generating `result` and `zero`, signed `lt`, and unsigned `ltu` flags | `a, b, alu_ctrl → result, zero, lt, ltu` |
| `rtl/imm_gen.v` | `imm_gen` | Combinational immediate bit-slicer and sign-extender supporting I, S, B, U, and J formats | `instr → imm` |
| `rtl/control.v` | `control` | Primary 7-bit opcode decoder generating 11 datapath, memory, and control-flow signals | `opcode → branch, jump, jalr, mem_read, mem_write, alu_src_a, alu_src_b, reg_write, result_src[1:0], alu_op[2:0]` |
| `rtl/data_mem.v` | `data_mem` | `256 × 32-bit` (1 KB) little-endian Data RAM with byte-lane write masking (`addr[1:0]`) and sign/zero load extension | `clk, mem_read, mem_write, funct3, addr, write_data → read_data` |
| `rtl/mux.v` | `mux2` | 32-bit 2-to-1 combinational multiplexer instantiated for ALU Operand A (`alu_mux_a`) and Operand B (`alu_mux_b`) | `a, b, sel → y` |

---

## Repository Structure

```text
RV32I/
├── rtl/                        # Synthesizable Verilog RTL design files (9 modules)
│   ├── core_top.v              # Top-level RV32I processor core
│   ├── pc.v                    # 32-bit Program Counter
│   ├── instr_mem.v             # 256x32 Instruction ROM
│   ├── reg_file.v              # 32x32 General-Purpose Register File
│   ├── alu.v                   # 32-bit Arithmetic Logic Unit
│   ├── imm_gen.v               # Multi-format Immediate Generator
│   ├── control.v               # Main Opcode Control Decoder
│   ├── data_mem.v              # 256x32 Byte-Addressable Data RAM
│   └── mux.v                   # 32-bit 2-to-1 Multiplexer
├── tb/                         # Self-checking ModelSim unit & system testbenches
│   ├── tb_core.v               # Full-core integration testbench (63 instructions, checks x0-x31 & DMEM)
│   ├── tb_alu.v                # Unit testbench for all 11 ALU operations & status flags
│   ├── tb_reg_file.v           # Unit testbench for dual-read, sync write & x0 protection
│   ├── tb_pc.v                 # Unit testbench for async reset & PC updates
│   ├── tb_instr_mem.v          # Unit testbench for word-aligned instruction fetch
│   ├── tb_imm_gen.v            # Unit testbench for I/S/B/U/J sign extension
│   ├── tb_control.v            # Unit testbench for all 10 opcode classes
│   ├── tb_data_mem.v           # Unit testbench for sb/sh/sw & lb/lh/lw/lbu/lhu
│   └── tb_mux.v                # Unit testbench for 2-to-1 multiplexer
├── sw/ 
│   └── asm_tests/
│       └── program.s           # Annotated 63-instruction RV32I assembly verification program
│   └── compiled_hex/
│       └── program.hex         # 63-word hexadecimal machine code image
├── extras/                     # ModelSim waveform formatter & run command (.do) scripts
├── REPORT DOCS/                # Architecture diagrams, decoding tables & CEP report files
├── core_top.qpf                # Intel Quartus Prime project file
├── core_top.qsf                # Intel Quartus Prime settings file
└── .gitignore                  # Excludes Quartus/ModelSim generated build artifacts
```

---

## ModelSim Simulation and Verification

All testbenches are **self-checking** using 4-state equality (`===`) and output `[PASS]` / `[FAIL]` diagnostics with a final pass/fail summary in the ModelSim Transcript.

### 1. Running the Full-Core Testbench (`tb_core`)

Launch **ModelSim-Altera**, change directory to the repository root (`RV32I/`), and run the following commands in the **Transcript** window:

```tcl
vlib work
vlog "rtl/*.v" "tb/tb_core.v"
vsim -voptargs="+acc" work.tb_core
add wave -r /*
run -all
```

*(Optional: Use the waveform formatter `.do` scripts inside `extras/` to group signals into sectioned views for register setup, R-type, I-type, memory access, branch evaluation, and jump link verification.)*

### 2. What `tb_core` Verifies

- **Architectural Registers (`x0`–`x31`):** Confirms `x0` remains `0` after `addi x0, x0, 5`, and verifies exact outputs across all R-type, I-type, `LUI`, `AUIPC`, load, and jump link registers (`x29 = 0x000000E8` for `JAL`, `x31 = 0x000000F4` for `JALR`).
- **6-Condition Branch Scoreboard (`x30`):** Exercises `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, and `BGEU` in both taken and not-taken scenarios. Each of the six not-taken branches increments `x30` by `16` (`0x10`), yielding a final verified score of **`96` (`0x00000060`)**.
- **Data Memory (`dmem[0]`, `dmem[1]`):** Confirms merged little-endian `SW` + `SB` + `SH` writes (`0x000A0AFD` at `dmem[0]`) and signed/unsigned byte and halfword reads (`LB`, `LBU`, `LH`, `LHU`, `LW`).

### 3. Running Individual Unit Testbenches

Replace `tb_core` with any module testbench (`tb_alu`, `tb_reg_file`, `tb_pc`, `tb_instr_mem`, `tb_imm_gen`, `tb_control`, `tb_data_mem`, or `tb_mux`):

```tcl
quit -sim
vlog "rtl/*.v" "tb/tb_alu.v"
vsim -voptargs="+acc" work.tb_alu
add wave -r /*
run -all
```

---

## Quartus Prime Synthesis

1. Open **Intel Quartus Prime Lite Edition 18.1**.
2. Select **File → Open Project...** and open `core_top.qpf`.
3. Verify `core_top` is set as the Top-Level Entity (**Assignments → Settings → General**).
4. Run **Processing → Start Compilation** (`Ctrl + L`) to complete Analysis & Synthesis, Fitter, Assembler, and TimeQuest Timing Analysis (**0 errors**).
5. View the synthesized hardware schematic via **Tools → Netlist Viewers → RTL Viewer**.

---

## Project Team

- **Institution:** NED University of Engineering & Technology, Karachi
- **Department:** Telecommunications Engineering
- **Course:** `(TC-205)` Digital Logic Design — Batch `2025-2029` | 3rd Semester | Section `B` | Year `2026`
- **Course Teacher:** Dr. Fahim-ul-Haque

| Name | Seat No. |
| :--- | :--- |
| **Muhammad Abdullah Elahi** | `TC-25061` |
| **Muhammad Hamza** | `TC-25062` |
| **Muhammad Shafay Khan** | `TC-25063` |
| **Muhammad Hassan Riaz** | `TC-25064` |
| **Muhammad Fasih** | `TC-25066` |

---

## References

1. S. L. Harris and D. Harris, *Digital Design and Computer Architecture: RISC-V Edition*, Morgan Kaufmann, 2021.
2. A. Waterman and K. Asanović (Eds.), *The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA*, RISC-V International.