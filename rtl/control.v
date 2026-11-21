module control (
    input  [6:0] opcode,
    output reg       branch,
    output reg       jump,       // High for JAL
    output reg       jalr,       // High for JALR
    output reg       mem_read,
    output reg [1:0] result_src, // 2'b00: ALU, 2'b01: DataMem, 2'b10: PC+4
    output reg [2:0] alu_op,     // 3'b000: ADD, 3'b001: Branch, 3'b010: R-type, 3'b011: I-type, 3'b100: PASS_B
    output reg       mem_write,
    output reg       alu_src_a,  // 1'b0: rs1_data, 1'b1: PC (for AUIPC)
    output reg       alu_src_b,  // 1'b0: rs2_data, 1'b1: imm
    output reg       reg_write
);

    // RV32I Base Opcodes
    localparam OP_R_TYPE = 7'b0110011; // 7'h33: add, sub, sll, slt, sltu, xor, srl, sra, or, and
    localparam OP_I_ALU  = 7'b0010011; // 7'h13: addi, slti, sltiu, xori, ori, andi, slli, srli, srai
    localparam OP_LOAD   = 7'b0000011; // 7'h03: lb, lh, lw, lbu, lhu
    localparam OP_STORE  = 7'b0100011; // 7'h23: sb, sh, sw
    localparam OP_BRANCH = 7'b1100011; // 7'h63: beq, bne, blt, bge, bltu, bgeu
    localparam OP_LUI    = 7'b0110111; // 7'h37: lui
    localparam OP_AUIPC  = 7'b0010111; // 7'h17: auipc
    localparam OP_JAL    = 7'b1101111; // 7'h6F: jal
    localparam OP_JALR   = 7'b1100111; // 7'h67: jalr
    localparam OP_FENCE  = 7'b0001111; // 7'h0F: fence, fence.i (NOP in single-cycle)
    localparam OP_SYSTEM = 7'b1110011; // 7'h73: ecall, ebreak

    always @(*) begin
        // Default assignments prevent inferred latches
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;
        mem_read   = 1'b0;
        result_src = 2'b00;
        alu_op     = 3'b000;
        mem_write  = 1'b0;
        alu_src_a  = 1'b0;
        alu_src_b  = 1'b0;
        reg_write  = 1'b0;

        case (opcode)
            OP_R_TYPE: begin
                reg_write  = 1'b1;
                alu_op     = 3'b010; // Decode funct3 & funct7
            end

            OP_I_ALU: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;   // Use immediate
                alu_op     = 3'b011; // Decode funct3 (and funct7 for shifts)
            end

            OP_LOAD: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                result_src = 2'b01;  // Write back from Data Memory
                alu_src_b  = 1'b1;   // Base addr + offset
                alu_op     = 3'b000; // Force ADD
            end

            OP_STORE: begin
                mem_write  = 1'b1;
                alu_src_b  = 1'b1;   // Base addr + offset
                alu_op     = 3'b000; // Force ADD
            end

            OP_BRANCH: begin
                branch     = 1'b1;
                alu_op     = 3'b001; // Force SUB (and generate zero, lt, ltu flags)
            end

            OP_LUI: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;   // Select U-type immediate
                alu_op     = 3'b100; // Force ALU_PASS_B
            end

            OP_AUIPC: begin
                reg_write  = 1'b1;
                alu_src_a  = 1'b1;   // Select PC
                alu_src_b  = 1'b1;   // Select U-type immediate
                alu_op     = 3'b000; // Force ADD (PC + imm)
            end

            OP_JAL: begin
                reg_write  = 1'b1;
                jump       = 1'b1;   // PC = PC + J-imm
                result_src = 2'b10;  // Write back PC + 4
            end

            OP_JALR: begin
                reg_write  = 1'b1;
                jalr       = 1'b1;   // PC = (rs1 + I-imm) & ~1
                alu_src_b  = 1'b1;   // Select I-type immediate
                alu_op     = 3'b000; // Force ADD (rs1 + imm)
                result_src = 2'b10;  // Write back PC + 4
            end

            OP_FENCE,
            OP_SYSTEM: begin
                // Safe NOP: all write/control signals stay at default 0
            end

            default: begin
                // Safe default for reserved/unrecognized opcodes
                branch     = 1'b0;
                jump       = 1'b0;
                jalr       = 1'b0;
                mem_read   = 1'b0;
                result_src = 2'b00;
                alu_op     = 3'b000;
                mem_write  = 1'b0;
                alu_src_a  = 1'b0;
                alu_src_b  = 1'b0;
                reg_write  = 1'b0;
            end
        endcase
    end
endmodule