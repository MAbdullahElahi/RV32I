`timescale 1ns/1ps

module tb_instr_mem;
    reg  [31:0] pc;
    wire [31:0] instr;

    integer pass_count = 0, fail_count = 0;

    instr_mem uut (
        .pc    (pc),
        .instr (instr)
    );

    task check_imem;
        input [31:0] addr, exp;
        begin
            pc = addr;
            #5;
            if (instr === exp) begin
                $display("[PASS] PC=%h -> instr=%h", pc, instr);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] PC=%h -> Got %h, Expected %h", pc, instr, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        // Preload test instructions into ROM array
        uut.mem[0] = 32'h0050_0093; // addi x1, x0, 5
        uut.mem[1] = 32'h00A0_0113; // addi x2, x0, 10
        uut.mem[2] = 32'h0020_81B3; // add  x3, x1, x2
        uut.mem[3] = 32'h0030_2023; // sw   x3, 0(x0)

        check_imem(32'h0000_0000, 32'h0050_0093);
        check_imem(32'h0000_0004, 32'h00A0_0113);
        check_imem(32'h0000_0008, 32'h0020_81B3);
        check_imem(32'h0000_000C, 32'h0030_2023);

        $display("InstrMem Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $stop;
    end
endmodule