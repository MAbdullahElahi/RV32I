# =============================================================================
# RV32I single-cycle core - verification program (63 instructions, all 37 RV32I base instructions)
# Matches sw/compiled_hex/program.hex word for word. Result of every line is in its comment;
# tb/tb_core.v checks x0..x31 and data memory words 0 and 1 against these values.
# =============================================================================
        .text
        .globl _start
_start:

        # ---- setup values / LUI / AUIPC ----
        addi x1, x0, 10          # 0x00: x1 = 10
        addi x2, x0, -3          # 0x04: x2 = -3
        addi x3, x0, 4           # 0x08: x3 = 4 (shift amount used below)
        lui x4, 0x12345          # 0x0C: x4 = 0x12345000 (upper immediate)
        auipc x5, 0x1            # 0x10: x5 = PC(0x10) + 0x1000 = 0x1010
        addi x0, x0, 5           # 0x14: write to x0 is ignored, x0 stays 0

        # ---- R-type: ADD SUB SLL SLT SLTU XOR SRL SRA OR AND ----
        add x6, x1, x2           # 0x18: x6  = 10 + (-3) = 7
        sub x7, x1, x2           # 0x1C: x7  = 10 - (-3) = 13
        sll x8, x1, x3           # 0x20: x8  = 10 << 4 = 160
        slt x9, x2, x1           # 0x24: x9  = (-3 < 10) signed = 1
        sltu x10, x2, x1         # 0x28: x10 = (0xFFFFFFFD < 10) unsigned = 0
        xor x11, x1, x2          # 0x2C: x11 = 10 ^ -3 = -9
        srl x12, x2, x3          # 0x30: x12 = -3 >> 4 logical = 0x0FFFFFFF
        sra x13, x2, x3          # 0x34: x13 = -3 >> 4 arithmetic = -1
        or x14, x1, x2           # 0x38: x14 = 10 | -3 = -1
        and x15, x1, x2          # 0x3C: x15 = 10 & -3 = 8

        # ---- I-type: SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI ----
        slti x16, x2, -2         # 0x40: x16 = (-3 < -2) signed = 1
        sltiu x17, x1, -1        # 0x44: x17 = (10 < 0xFFFFFFFF) unsigned = 1
        xori x18, x1, 85         # 0x48: x18 = 10 ^ 0x55 = 0x5F
        ori x19, x1, 48          # 0x4C: x19 = 10 | 0x30 = 0x3A
        andi x20, x2, 255        # 0x50: x20 = -3 & 0xFF = 0xFD
        slli x21, x1, 3          # 0x54: x21 = 10 << 3 = 80
        srli x22, x2, 28         # 0x58: x22 = -3 >> 28 logical = 0xF
        srai x23, x2, 1          # 0x5C: x23 = -3 >> 1 arithmetic = -2

        # ---- stores: SW SB SH SW ----
        sw x2, 0(x0)             # 0x60: mem[0] = 0xFFFFFFFD
        sb x1, 1(x0)             # 0x64: byte 1 of mem[0] = 0x0A -> 0xFFFF0AFD
        sh x1, 2(x0)             # 0x68: upper half of mem[0] = 0x000A -> 0x000A0AFD
        sw x2, 4(x0)             # 0x6C: mem[4] = 0xFFFFFFFD

        # ---- loads: LW LB LBU LH LHU ----
        lw x24, 0(x0)            # 0x70: x24 = 0x000A0AFD (checks sw + sb + sh merged)
        lb x25, 4(x0)            # 0x74: x25 = 0xFFFFFFFD (byte, sign-extended)
        lbu x26, 4(x0)           # 0x78: x26 = 0x000000FD (byte, zero-extended)
        lh x27, 4(x0)            # 0x7C: x27 = 0xFFFFFFFD (halfword, sign-extended)
        lhu x28, 4(x0)           # 0x80: x28 = 0x0000FFFD (halfword, zero-extended)

        # ---- branches: each one taken and not taken (BEQ BNE BLT BGE BLTU BGEU) ----
        beq x1, x1, L_8C         # 0x84: BEQ taken -> skips the next line
        addi x30, x30, 1         # 0x88: must be skipped (would add 1 to x30)
L_8C:
        beq x1, x2, L_94         # 0x8C: BEQ NOT taken -> falls through
        addi x30, x30, 16        # 0x90: x30 += 16 (final x30 = 6 x 16 = 96)
L_94:
        bne x1, x2, L_9C         # 0x94: BNE taken -> skips the next line
        addi x30, x30, 1         # 0x98: must be skipped (would add 1 to x30)
L_9C:
        bne x1, x1, L_A4         # 0x9C: BNE NOT taken -> falls through
        addi x30, x30, 16        # 0xA0: x30 += 16 (final x30 = 6 x 16 = 96)
L_A4:
        blt x2, x1, L_AC         # 0xA4: BLT taken -> skips the next line
        addi x30, x30, 1         # 0xA8: must be skipped (would add 1 to x30)
L_AC:
        blt x1, x2, L_B4         # 0xAC: BLT NOT taken -> falls through
        addi x30, x30, 16        # 0xB0: x30 += 16 (final x30 = 6 x 16 = 96)
L_B4:
        bge x1, x2, L_BC         # 0xB4: BGE taken -> skips the next line
        addi x30, x30, 1         # 0xB8: must be skipped (would add 1 to x30)
L_BC:
        bge x2, x1, L_C4         # 0xBC: BGE NOT taken -> falls through
        addi x30, x30, 16        # 0xC0: x30 += 16 (final x30 = 6 x 16 = 96)
L_C4:
        bltu x1, x2, L_CC        # 0xC4: BLTU taken -> skips the next line
        addi x30, x30, 1         # 0xC8: must be skipped (would add 1 to x30)
L_CC:
        bltu x2, x1, L_D4        # 0xCC: BLTU NOT taken -> falls through
        addi x30, x30, 16        # 0xD0: x30 += 16 (final x30 = 6 x 16 = 96)
L_D4:
        bgeu x2, x1, L_DC        # 0xD4: BGEU taken -> skips the next line
        addi x30, x30, 1         # 0xD8: must be skipped (would add 1 to x30)
L_DC:
        bgeu x1, x2, L_E4        # 0xDC: BGEU NOT taken -> falls through
        addi x30, x30, 16        # 0xE0: x30 += 16 (final x30 = 6 x 16 = 96)

        # ---- jumps: JAL, JALR ----
L_E4:
        jal x29, L_EC            # 0xE4: JAL: x29 = PC+4 = 0xE8, jump over the next line
        addi x30, x30, 100       # 0xE8: must be skipped by JAL
L_EC:
        addi x31, x0, 248        # 0xEC: x31 = 248 (0xF8, address of the last line)
        jalr x31, 1(x31)         # 0xF0: JALR to 249: bit 0 cleared -> 0xF8, x31 = PC+4 = 0xF4
        addi x30, x30, 100       # 0xF4: must be skipped by JALR

        # ---- end ----
L_F8:
        jal x0, L_F8             # 0xF8: end of program: jump to itself
