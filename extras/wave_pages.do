# Labeled, paged waveforms for tb_core (module renamed to tb_core).
# Use (a simulation must be loaded, i.e. after vsim):
#     do wave_pages.do        -> runs the test and shows page 1
#     page1 ... page6         -> switch pages; screenshot each one

proc reg {n label} {
    add wave -label $label -radix hex "/tb_core/uut/rf/rf\[$n\]"
}

proc common {} {
    add wave -divider "CLOCK"
    add wave -label "Clock"                         /tb_core/clk
    add wave -divider "WHICH INSTRUCTION"
    add wave -label "PC (address)"        -radix hex /tb_core/uut/pc_current
    add wave -label "Instruction (hex)"   -radix hex /tb_core/uut/instr
    add wave -divider "ALU"
    add wave -label "ALU input A"         -radix hex /tb_core/uut/alu_a
    add wave -label "ALU input B"         -radix hex /tb_core/uut/alu_b
    add wave -label "ALU result"          -radix hex /tb_core/uut/alu_result
    add wave -label "Value written to rd" -radix hex /tb_core/uut/rd_data
    add wave -label "reg_write (save)"              /tb_core/uut/reg_write
}

proc newpage {} {
    delete wave *
    common
}

proc finish {t0 t1} {
    configure wave -namecolwidth 250
    configure wave -valuecolwidth 110
    wave zoom range $t0 $t1
}

proc page1 {} {   ;# 0-65 ns : ADDI x3, LUI, AUIPC, ADDI x0
    newpage
    add wave -divider "RESULTS SAVED"
    reg 0  "x0  stays 0 (addi x0)"
    reg 1  "x1  addi = 10"
    reg 2  "x2  addi = -3"
    reg 3  "x3  addi = 4"
    reg 4  "x4  lui"
    reg 5  "x5  auipc"
    finish 0ns 65ns
}

proc page2 {} {   ;# 65-165 ns : R-type
    newpage
    add wave -divider "R-TYPE RESULTS"
    reg 6  "x6  ADD"
    reg 7  "x7  SUB"
    reg 8  "x8  SLL"
    reg 9  "x9  SLT"
    reg 10 "x10 SLTU"
    reg 11 "x11 XOR"
    reg 12 "x12 SRL"
    reg 13 "x13 SRA"
    reg 14 "x14 OR"
    reg 15 "x15 AND"
    finish 65ns 165ns
}

proc page3 {} {   ;# 165-245 ns : I-type
    newpage
    add wave -label "alu_src_b (1 = immediate)" /tb_core/uut/alu_src_b
    add wave -label "Immediate" -radix hex      /tb_core/uut/imm
    add wave -divider "I-TYPE RESULTS"
    reg 16 "x16 SLTI"
    reg 17 "x17 SLTIU"
    reg 18 "x18 XORI"
    reg 19 "x19 ORI"
    reg 20 "x20 ANDI"
    reg 21 "x21 SLLI"
    reg 22 "x22 SRLI"
    reg 23 "x23 SRAI"
    finish 165ns 245ns
}

proc page4 {} {   ;# 245-335 ns : stores and loads
    newpage
    add wave -divider "MEMORY"
    add wave -label "mem_write (store)"             /tb_core/uut/mem_write
    add wave -label "mem_read (load)"               /tb_core/uut/mem_read
    add wave -label "Data read from memory" -radix hex /tb_core/uut/mem_rd
    add wave -label "Memory word 0" -radix hex  "/tb_core/uut/dmem/dmem\[0\]"
    add wave -label "Memory word 1" -radix hex  "/tb_core/uut/dmem/dmem\[1\]"
    add wave -divider "LOAD RESULTS"
    reg 24 "x24 LW"
    reg 25 "x25 LB"
    reg 26 "x26 LBU"
    reg 27 "x27 LH"
    reg 28 "x28 LHU"
    finish 245ns 335ns
}

proc page5 {} {   ;# 335-515 ns : branches
    newpage
    add wave -divider "BRANCH LOGIC"
    add wave -label "branch (is a branch)"          /tb_core/uut/branch
    add wave -label "Condition true?"               /tb_core/uut/branch_cond
    add wave -label "Branch taken (PC jumps)"       /tb_core/uut/take_branch_or_jal
    add wave -label "zero (a == b)"                 /tb_core/uut/zero
    add wave -label "lt  (a < b signed)"            /tb_core/uut/lt
    add wave -label "ltu (a < b unsigned)"          /tb_core/uut/ltu
    add wave -divider "SCORE"
    reg 30 "x30 branch score (ends at 0x60)"
    finish 335ns 515ns
}

proc page6 {} {   ;# 505-560 ns : JAL and JALR
    newpage
    add wave -divider "JUMPS"
    add wave -label "jump (JAL)"                    /tb_core/uut/jump
    add wave -label "jalr (JALR)"                   /tb_core/uut/jalr
    add wave -label "Next PC" -radix hex            /tb_core/uut/pc_next
    add wave -divider "LINK ADDRESSES"
    reg 29 "x29 JAL  link"
    reg 31 "x31 JALR link"
    finish 505ns 560ns
}

# ---- run the test with every signal logged, then show page 1 ----
restart -force
log -r /*
run -all
page1
