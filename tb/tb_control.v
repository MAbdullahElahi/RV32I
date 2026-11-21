`timescale 1ns/1ps

module tb_control;
    reg  [6:0] opcode;
    wire       branch, jump, jalr, mem_read, mem_write, alu_src_a, alu_src_b, reg_write;
    wire [1:0] result_src;
    wire [2:0] alu_op;

    integer pass_count = 0, fail_count = 0;

    control uut (
        .opcode(opcode), .branch(branch), .jump(jump), .jalr(jalr),
        .mem_read(mem_read), .result_src(result_src), .alu_op(alu_op),
        .mem_write(mem_write), .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .reg_write(reg_write)
    );

    task check_ctrl;
        input [127:0] name;
        input [6:0]   op;
        input [12:0]  exp_vec; // {reg_write, alu_src_a, alu_src_b, alu_op[2:0], mem_read, mem_write, result_src[1:0], branch, jump, jalr}
        reg   [12:0]  got_vec;
        begin
            opcode = op; #5;
            got_vec = {reg_write, alu_src_a, alu_src_b, alu_op, mem_read, mem_write, result_src, branch, jump, jalr};
            if (got_vec === exp_vec) begin
                $display("[PASS] %0s (op=%h)", name, op);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s (op=%h) -> Got %b, Exp %b", name, op, got_vec, exp_vec);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        check_ctrl("R-Type", 7'h33, 13'b1_0_0_010_0_0_00_0_0_0);
        check_ctrl("I-ALU",  7'h13, 13'b1_0_1_011_0_0_00_0_0_0);
        check_ctrl("Load",   7'h03, 13'b1_0_1_000_1_0_01_0_0_0);
        check_ctrl("Store",  7'h23, 13'b0_0_1_000_0_1_00_0_0_0);
        check_ctrl("Branch", 7'h63, 13'b0_0_0_001_0_0_00_1_0_0);
        check_ctrl("LUI",    7'h37, 13'b1_0_1_100_0_0_00_0_0_0);
        check_ctrl("AUIPC",  7'h17, 13'b1_1_1_000_0_0_00_0_0_0);
        check_ctrl("JAL",    7'h6F, 13'b1_0_0_000_0_0_10_0_1_0);
        check_ctrl("JALR",   7'h67, 13'b1_0_1_000_0_0_10_0_0_1);
        check_ctrl("SYSTEM", 7'h73, 13'b0_0_0_000_0_0_00_0_0_0);

        $display("Control Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $stop;
    end
endmodule