# Labeled waveform setup for tb_core_top
# Usage (after vsim): do wave_labeled.do   then:  run -all
delete wave *

add wave -divider "CLOCK / RESET"
add wave -label "Clock"                          /tb_core_top/clk
add wave -label "Reset"                          /tb_core_top/rst

add wave -divider "FETCH"
add wave -label "PC (current address)"  -radix hex /tb_core_top/uut/pc_current
add wave -label "Instruction"           -radix hex /tb_core_top/uut/instr

add wave -divider "CONTROL SIGNALS"
add wave -label "reg_write (save result)"        /tb_core_top/uut/reg_write
add wave -label "alu_src_b (1=immediate)"        /tb_core_top/uut/alu_src_b
add wave -label "mem_write (store)"              /tb_core_top/uut/mem_write
add wave -label "mem_read (load)"                /tb_core_top/uut/mem_read
add wave -label "branch"                         /tb_core_top/uut/branch
add wave -label "jump (JAL)"                     /tb_core_top/uut/jump
add wave -label "jalr (JALR)"                    /tb_core_top/uut/jalr

add wave -divider "ALU"
add wave -label "ALU input A"           -radix hex /tb_core_top/uut/alu_a
add wave -label "ALU input B"           -radix hex /tb_core_top/uut/alu_b
add wave -label "ALU result"            -radix hex /tb_core_top/uut/alu_result
add wave -label "Immediate"             -radix hex /tb_core_top/uut/imm

add wave -divider "MEMORY / WRITE-BACK"
add wave -label "Data read from memory" -radix hex /tb_core_top/uut/mem_rd
add wave -label "Value written to rd"   -radix hex /tb_core_top/uut/rd_data

add wave -divider "REGISTERS (saved results)"
add wave -label "x1  (10)"              -radix hex {/tb_core_top/uut/rf/rf[1]}
add wave -label "x2  (-3)"              -radix hex {/tb_core_top/uut/rf/rf[2]}
add wave -label "x3  (4)"               -radix hex {/tb_core_top/uut/rf/rf[3]}
add wave -label "x4  LUI"               -radix hex {/tb_core_top/uut/rf/rf[4]}
add wave -label "x5  AUIPC"             -radix hex {/tb_core_top/uut/rf/rf[5]}
add wave -label "x6  ADD"               -radix hex {/tb_core_top/uut/rf/rf[6]}
add wave -label "x7  SUB"               -radix hex {/tb_core_top/uut/rf/rf[7]}
add wave -label "x8  SLL"               -radix hex {/tb_core_top/uut/rf/rf[8]}
add wave -label "x9  SLT"               -radix hex {/tb_core_top/uut/rf/rf[9]}
add wave -label "x10 SLTU"              -radix hex {/tb_core_top/uut/rf/rf[10]}
add wave -label "x11 XOR"               -radix hex {/tb_core_top/uut/rf/rf[11]}
add wave -label "x12 SRL"               -radix hex {/tb_core_top/uut/rf/rf[12]}
add wave -label "x13 SRA"               -radix hex {/tb_core_top/uut/rf/rf[13]}
add wave -label "x14 OR"                -radix hex {/tb_core_top/uut/rf/rf[14]}
add wave -label "x15 AND"               -radix hex {/tb_core_top/uut/rf/rf[15]}
add wave -label "x16 SLTI"              -radix hex {/tb_core_top/uut/rf/rf[16]}
add wave -label "x17 SLTIU"             -radix hex {/tb_core_top/uut/rf/rf[17]}
add wave -label "x18 XORI"              -radix hex {/tb_core_top/uut/rf/rf[18]}
add wave -label "x19 ORI"               -radix hex {/tb_core_top/uut/rf/rf[19]}
add wave -label "x20 ANDI"              -radix hex {/tb_core_top/uut/rf/rf[20]}
add wave -label "x21 SLLI"              -radix hex {/tb_core_top/uut/rf/rf[21]}
add wave -label "x22 SRLI"              -radix hex {/tb_core_top/uut/rf/rf[22]}
add wave -label "x23 SRAI"              -radix hex {/tb_core_top/uut/rf/rf[23]}
add wave -label "x24 LW"                -radix hex {/tb_core_top/uut/rf/rf[24]}
add wave -label "x25 LB"                -radix hex {/tb_core_top/uut/rf/rf[25]}
add wave -label "x26 LBU"               -radix hex {/tb_core_top/uut/rf/rf[26]}
add wave -label "x27 LH"                -radix hex {/tb_core_top/uut/rf/rf[27]}
add wave -label "x28 LHU"               -radix hex {/tb_core_top/uut/rf/rf[28]}
add wave -label "x29 JAL link"          -radix hex {/tb_core_top/uut/rf/rf[29]}
add wave -label "x30 branch score"      -radix hex {/tb_core_top/uut/rf/rf[30]}
add wave -label "x31 JALR link"         -radix hex {/tb_core_top/uut/rf/rf[31]}

configure wave -namecolwidth 260
configure wave -valuecolwidth 110
