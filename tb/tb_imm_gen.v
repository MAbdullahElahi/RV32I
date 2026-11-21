`timescale 1ns/1ps

module tb_imm_gen;
    reg  [31:0] instr;
    wire [31:0] imm;

    integer pass_count = 0, fail_count = 0;

    imm_gen uut (.instr(instr), .imm(imm));

    task check_imm;
        input [127:0] name;
        input [31:0]  in_instr, exp_imm;
        begin
            instr = in_instr; #5;
            if (imm === exp_imm) begin
                $display("[PASS] %0s -> imm=%h", name, imm);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s -> Got %h, Expected %h", name, imm, exp_imm);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        // I-Type: addi x1, x0, -16 (0xFF000093) -> 0xFFFFFFF0
        check_imm("I-Type (-16)",  32'hFF00_0093, 32'hFFFF_FFF0);
        // S-Type: sw x2, -4(x1) (0xFE20AE23) -> 0xFFFFFFFC
        check_imm("S-Type (-4)",   32'hFE20_AE23, 32'hFFFF_FFFC);
        // B-Type: beq x1, x2, -8 (0xFE208CE3) -> 0xFFFFFFF8
        check_imm("B-Type (-8)",   32'hFE20_8CE3, 32'hFFFF_FFF8);
        // U-Type: lui x1, 0x12345 (0x123450B7) -> 0x12345000
        check_imm("U-Type (LUI)",  32'h1234_50B7, 32'h1234_5000);
        // J-Type: jal x1, -8 (0xFF9FF0EF) -> 0xFFFFFFF8
        check_imm("J-Type (-8)",   32'hFF9F_F0EF, 32'hFFFF_FFF8);

        $display("ImmGen Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $stop;
    end
endmodule