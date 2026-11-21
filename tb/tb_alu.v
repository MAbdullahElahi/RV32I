`timescale 1ns/1ps

module tb_alu;
    reg  [31:0] a, b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero, lt, ltu;

    integer pass_count = 0, fail_count = 0;

    localparam ALU_ADD = 4'b0000, ALU_SUB = 4'b0001, ALU_AND = 4'b0010, ALU_OR   = 4'b0011,
               ALU_XOR = 4'b0100, ALU_SLT = 4'b0101, ALU_SLTU= 4'b0110, ALU_SLL  = 4'b0111,
               ALU_SRL = 4'b1000, ALU_SRA = 4'b1001, ALU_PASS_B = 4'b1010;

    alu uut (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .zero(zero), .lt(lt), .ltu(ltu));

    task check_alu;
        input [127:0] name;
        input [31:0]  in_a, in_b;
        input [3:0]   ctrl;
        input [31:0]  exp_res;
        input         exp_z, exp_lt, exp_ltu;
        begin
            a = in_a; b = in_b; alu_ctrl = ctrl; #10;
            if (result === exp_res && zero === exp_z && lt === exp_lt && ltu === exp_ltu) begin
                $display("[PASS] %0s -> res=%h", name, result);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s -> Got res=%h (Z=%b,LT=%b,LTU=%b), Exp=%h (%b,%b,%b)",
                         name, result, zero, lt, ltu, exp_res, exp_z, exp_lt, exp_ltu);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        check_alu("ADD",       32'd10, 32'd5,  ALU_ADD,    32'd15,       0, 0, 0);
        check_alu("SUB Zero",  32'd10, 32'd10, ALU_SUB,    32'd0,        1, 0, 0);
        check_alu("AND",       32'h0A, 32'h05, ALU_AND,    32'd0,        1, 0, 0);
        check_alu("OR",        32'h0A, 32'h05, ALU_OR,     32'h0F,       0, 0, 0);
        check_alu("XOR",       32'h0A, 32'h06, ALU_XOR,    32'h0C,       0, 0, 0);
        check_alu("SLT (-10<5)", -32'd10, 32'd5, ALU_SLT,  32'd1,        0, 1, 0);
        check_alu("SLTU(-10<5)", -32'd10, 32'd5, ALU_SLTU, 32'd0,        1, 1, 0);
        check_alu("SLL",       32'd1,  32'd4,  ALU_SLL,    32'd16,       0, 1, 1);
        check_alu("SRL",      -32'd16, 32'd2,  ALU_SRL,    32'h3FFF_FFFC,0, 1, 0);
        check_alu("SRA",      -32'd16, 32'd2,  ALU_SRA,   -32'd4,        0, 1, 0);
        check_alu("PASS_B",    32'd0,  32'h1234_5000, ALU_PASS_B, 32'h1234_5000, 0, 1, 1);

        $display("ALU Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $stop;
    end
endmodule