`timescale 1ns/1ps


module tb_core_top;
    reg clk;
    reg rst;

    integer pass_count = 0;
    integer fail_count = 0;

    core_top uut (
        .clk (clk),
        .rst (rst)
    );

    // 100 MHz clock (10 ns period)
    always #5 clk = ~clk;

    task check_reg;
        input [4:0]  reg_num;
        input [31:0] exp_val;
        begin
            if (uut.rf.rf[reg_num] === exp_val) begin
                $display("[PASS] x%0d = 0x%08h (%0d)", reg_num, uut.rf.rf[reg_num], $signed(uut.rf.rf[reg_num]));
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] x%0d = 0x%08h, Expected 0x%08h", reg_num, uut.rf.rf[reg_num], exp_val);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_mem;
        input [7:0]  word_idx;
        input [31:0] exp_val;
        begin
            if (uut.dmem.dmem[word_idx] === exp_val) begin
                $display("[PASS] dmem[%0d] = 0x%08h", word_idx, uut.dmem.dmem[word_idx]);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] dmem[%0d] = 0x%08h, Expected 0x%08h", word_idx, uut.dmem.dmem[word_idx], exp_val);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;

        // Wait 1 ns so this load always happens after instr_mem's own initial block
        // (NOP fill + $readmemh), whatever order the simulator runs them in.
        #1;
        // 0x00: addi  x1, x0, 10
        uut.imem.mem[0] = 32'h00A00093;
        // 0x04: addi  x2, x0, -3
        uut.imem.mem[1] = 32'hFFD00113;
        // 0x08: addi  x3, x0, 4
        uut.imem.mem[2] = 32'h00400193;
        // 0x0C: lui   x4, 0x12345
        uut.imem.mem[3] = 32'h12345237;
        // 0x10: auipc x5, 0x1
        uut.imem.mem[4] = 32'h00001297;
        // 0x14: addi  x0, x0, 5
        uut.imem.mem[5] = 32'h00500013;
        // 0x18: add   x6, x1, x2
        uut.imem.mem[6] = 32'h00208333;
        // 0x1C: sub   x7, x1, x2
        uut.imem.mem[7] = 32'h402083B3;
        // 0x20: sll   x8, x1, x3
        uut.imem.mem[8] = 32'h00309433;
        // 0x24: slt   x9, x2, x1
        uut.imem.mem[9] = 32'h001124B3;
        // 0x28: sltu  x10, x2, x1
        uut.imem.mem[10] = 32'h00113533;
        // 0x2C: xor   x11, x1, x2
        uut.imem.mem[11] = 32'h0020C5B3;
        // 0x30: srl   x12, x2, x3
        uut.imem.mem[12] = 32'h00315633;
        // 0x34: sra   x13, x2, x3
        uut.imem.mem[13] = 32'h403156B3;
        // 0x38: or    x14, x1, x2
        uut.imem.mem[14] = 32'h0020E733;
        // 0x3C: and   x15, x1, x2
        uut.imem.mem[15] = 32'h0020F7B3;
        // 0x40: slti  x16, x2, -2
        uut.imem.mem[16] = 32'hFFE12813;
        // 0x44: sltiu x17, x1, -1
        uut.imem.mem[17] = 32'hFFF0B893;
        // 0x48: xori  x18, x1, 85
        uut.imem.mem[18] = 32'h0550C913;
        // 0x4C: ori   x19, x1, 48
        uut.imem.mem[19] = 32'h0300E993;
        // 0x50: andi  x20, x2, 255
        uut.imem.mem[20] = 32'h0FF17A13;
        // 0x54: slli  x21, x1, 3
        uut.imem.mem[21] = 32'h00309A93;
        // 0x58: srli  x22, x2, 28
        uut.imem.mem[22] = 32'h01C15B13;
        // 0x5C: srai  x23, x2, 1
        uut.imem.mem[23] = 32'h40115B93;
        // 0x60: sw    x2, 0(x0)
        uut.imem.mem[24] = 32'h00202023;
        // 0x64: sb    x1, 1(x0)
        uut.imem.mem[25] = 32'h001000A3;
        // 0x68: sh    x1, 2(x0)
        uut.imem.mem[26] = 32'h00101123;
        // 0x6C: sw    x2, 4(x0)
        uut.imem.mem[27] = 32'h00202223;
        // 0x70: lw    x24, 0(x0)
        uut.imem.mem[28] = 32'h00002C03;
        // 0x74: lb    x25, 4(x0)
        uut.imem.mem[29] = 32'h00400C83;
        // 0x78: lbu   x26, 4(x0)
        uut.imem.mem[30] = 32'h00404D03;
        // 0x7C: lh    x27, 4(x0)
        uut.imem.mem[31] = 32'h00401D83;
        // 0x80: lhu   x28, 4(x0)
        uut.imem.mem[32] = 32'h00405E03;
        // 0x84: beq   x1, x1, +8
        uut.imem.mem[33] = 32'h00108463;
        // 0x88: addi  x30, x30, 1
        uut.imem.mem[34] = 32'h001F0F13;
        // 0x8C: beq   x1, x2, +8
        uut.imem.mem[35] = 32'h00208463;
        // 0x90: addi  x30, x30, 16
        uut.imem.mem[36] = 32'h010F0F13;
        // 0x94: bne   x1, x2, +8
        uut.imem.mem[37] = 32'h00209463;
        // 0x98: addi  x30, x30, 1
        uut.imem.mem[38] = 32'h001F0F13;
        // 0x9C: bne   x1, x1, +8
        uut.imem.mem[39] = 32'h00109463;
        // 0xA0: addi  x30, x30, 16
        uut.imem.mem[40] = 32'h010F0F13;
        // 0xA4: blt   x2, x1, +8
        uut.imem.mem[41] = 32'h00114463;
        // 0xA8: addi  x30, x30, 1
        uut.imem.mem[42] = 32'h001F0F13;
        // 0xAC: blt   x1, x2, +8
        uut.imem.mem[43] = 32'h0020C463;
        // 0xB0: addi  x30, x30, 16
        uut.imem.mem[44] = 32'h010F0F13;
        // 0xB4: bge   x1, x2, +8
        uut.imem.mem[45] = 32'h0020D463;
        // 0xB8: addi  x30, x30, 1
        uut.imem.mem[46] = 32'h001F0F13;
        // 0xBC: bge   x2, x1, +8
        uut.imem.mem[47] = 32'h00115463;
        // 0xC0: addi  x30, x30, 16
        uut.imem.mem[48] = 32'h010F0F13;
        // 0xC4: bltu  x1, x2, +8
        uut.imem.mem[49] = 32'h0020E463;
        // 0xC8: addi  x30, x30, 1
        uut.imem.mem[50] = 32'h001F0F13;
        // 0xCC: bltu  x2, x1, +8
        uut.imem.mem[51] = 32'h00116463;
        // 0xD0: addi  x30, x30, 16
        uut.imem.mem[52] = 32'h010F0F13;
        // 0xD4: bgeu  x2, x1, +8
        uut.imem.mem[53] = 32'h00117463;
        // 0xD8: addi  x30, x30, 1
        uut.imem.mem[54] = 32'h001F0F13;
        // 0xDC: bgeu  x1, x2, +8
        uut.imem.mem[55] = 32'h0020F463;
        // 0xE0: addi  x30, x30, 16
        uut.imem.mem[56] = 32'h010F0F13;
        // 0xE4: jal   x29, +8
        uut.imem.mem[57] = 32'h00800EEF;
        // 0xE8: addi  x30, x30, 100
        uut.imem.mem[58] = 32'h064F0F13;
        // 0xEC: addi  x31, x0, 248
        uut.imem.mem[59] = 32'h0F800F93;
        // 0xF0: jalr  x31, 1(x31)
        uut.imem.mem[60] = 32'h001F8FE7;
        // 0xF4: addi  x30, x30, 100
        uut.imem.mem[61] = 32'h064F0F13;
        // 0xF8: jal   x0, +0
        uut.imem.mem[62] = 32'h0000006F;

        // Release reset and run long enough for the whole program to finish
        // (the last instruction is a jump-to-self, so extra cycles are harmless)
        #11;
        rst = 0;
        repeat (70) @(posedge clk);
        #2;

        $display("==================================================");
        $display("   RV32I Full Core Verification (37 instructions)  ");
        $display("==================================================");
        check_reg(5'd0, 32'h00000000); // addi x0 must stay 0 (= 0)
        check_reg(5'd1, 32'h0000000A); // addi (= 10)
        check_reg(5'd2, 32'hFFFFFFFD); // addi (= -3)
        check_reg(5'd3, 32'h00000004); // addi (= 4)
        check_reg(5'd4, 32'h12345000); // lui (= 305418240)
        check_reg(5'd5, 32'h00001010); // auipc (PC=0x10, +0x1000) (= 4112)
        check_reg(5'd6, 32'h00000007); // add (= 7)
        check_reg(5'd7, 32'h0000000D); // sub (= 13)
        check_reg(5'd8, 32'h000000A0); // sll (= 160)
        check_reg(5'd9, 32'h00000001); // slt (signed: -3 < 10) (= 1)
        check_reg(5'd10, 32'h00000000); // sltu (unsigned: 0xFFFFFFFD < 10 is false) (= 0)
        check_reg(5'd11, 32'hFFFFFFF7); // xor (= -9)
        check_reg(5'd12, 32'h0FFFFFFF); // srl (= 268435455)
        check_reg(5'd13, 32'hFFFFFFFF); // sra (= -1)
        check_reg(5'd14, 32'hFFFFFFFF); // or (= -1)
        check_reg(5'd15, 32'h00000008); // and (= 8)
        check_reg(5'd16, 32'h00000001); // slti (= 1)
        check_reg(5'd17, 32'h00000001); // sltiu (= 1)
        check_reg(5'd18, 32'h0000005F); // xori (= 95)
        check_reg(5'd19, 32'h0000003A); // ori (= 58)
        check_reg(5'd20, 32'h000000FD); // andi (= 253)
        check_reg(5'd21, 32'h00000050); // slli (= 80)
        check_reg(5'd22, 32'h0000000F); // srli (= 15)
        check_reg(5'd23, 32'hFFFFFFFE); // srai (= -2)
        check_reg(5'd24, 32'h000A0AFD); // lw  (checks sw + sb + sh merged) (= 658173)
        check_reg(5'd25, 32'hFFFFFFFD); // lb  (sign-extended) (= -3)
        check_reg(5'd26, 32'h000000FD); // lbu (zero-extended) (= 253)
        check_reg(5'd27, 32'hFFFFFFFD); // lh  (sign-extended) (= -3)
        check_reg(5'd28, 32'h0000FFFD); // lhu (zero-extended) (= 65533)
        check_reg(5'd29, 32'h000000E8); // jal link = PC+4 of the jal (= 232)
        check_reg(5'd30, 32'h00000060); // branch scoreboard: 6 not-taken x 16 = 96, taken-branch poisons must add 0 (= 96)
        check_reg(5'd31, 32'h000000F4); // jalr link = PC+4 of the jalr (= 244)

        check_mem(8'd0, 32'h000A0AFD); // sw, then sb (lane 1) and sh (upper half) merged
        check_mem(8'd1, 32'hFFFFFFFD); // sw

        $display("==================================================");
        $display("Core Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("==================================================");
        $stop;
    end
endmodule