# Helper for running one unit testbench.
# Load once:   do C:/Mac/Home/Desktop/RV32I/run_unit.do
# Then run any module with:   unit <rtl file> <testbench file> <testbench MODULE name>
# Example:                    unit rtl/alu.v tb/tb_alu.v tb_alu

proc unit {rtl tb mod} {
    cd C:/Mac/Home/Desktop/RV32I
    catch {quit -sim}
    if {![file exists work]} {vlib work}
    vlog $rtl $tb
    vsim -voptargs=+acc work.$mod
    add wave -r /*
    run -all
    catch {wave zoom full}
}

# Edit the file names / module names below to match YOUR files, then type the line you need.
#   unit rtl/pc.v        tb/tb_pc.v        tb_pc
#   unit rtl/instr_mem.v tb/tb_instr_mem.v tb_instr_mem
#   unit rtl/reg_file.v  tb/tb_reg_file.v  tb_reg_file
#   unit rtl/alu.v       tb/tb_alu.v       tb_alu
#   unit rtl/imm_gen.v   tb/tb_imm_gen.v   tb_imm_gen
#   unit rtl/control.v   tb/tb_control.v   tb_control
#   unit rtl/data_mem.v  tb/tb_data_mem.v  tb_data_mem
#   unit rtl/mux.v       tb/tb_mux.v       tb_mux
