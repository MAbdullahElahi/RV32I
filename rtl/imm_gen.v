module imm_gen (
    input      [31:0] instr,
    output reg [31:0] imm
);

    // RV32I Base Opcodes that carry immediates
    localparam OP_I_ALU  = 7'b0010011; // 7'h13: addi, slti, sltiu, xori, ori, andi, slli, srli, srai
    localparam OP_LOAD   = 7'b0000011; // 7'h03: lb, lh, lw, lbu, lhu
    localparam OP_JALR   = 7'b1100111; // 7'h67: jalr
    localparam OP_STORE  = 7'b0100011; // 7'h23: sb, sh, sw
    localparam OP_BRANCH = 7'b1100011; // 7'h63: beq, bne, blt, bge, bltu, bgeu
    localparam OP_LUI    = 7'b0110111; // 7'h37: lui
    localparam OP_AUIPC  = 7'b0010111; // 7'h17: auipc
    localparam OP_JAL    = 7'b1101111; // 7'h6F: jal

    always @(*) begin
        // Default assignment prevents inferred latches
        imm = 32'd0;

        case (instr[6:0])
            // I-Type: 12-bit signed immediate instr[31:20]
            OP_I_ALU,
            OP_LOAD,
            OP_JALR: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            // S-Type: 12-bit signed immediate {instr[31:25], instr[11:7]}
            OP_STORE: begin
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // B-Type: 13-bit signed branch offset (LSB = 0 for 2-byte alignment)
            // Bits: [12]=instr[31], [11]=instr[7], [10:5]=instr[30:25], [4:1]=instr[11:8], [0]=1'b0
            OP_BRANCH: begin
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            // U-Type: 20-bit upper immediate placed in instr[31:12], lower 12 bits = 0
            OP_LUI,
            OP_AUIPC: begin
                imm = {instr[31:12], 12'd0};
            end

            // J-Type: 21-bit signed jump offset (LSB = 0 for 2-byte alignment)
            // Bits: [20]=instr[31], [19:12]=instr[19:12], [11]=instr[20], [10:1]=instr[30:21], [0]=1'b0
            OP_JAL: begin
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end

            // R-Type, FENCE, SYSTEM, or unknown opcodes: safe zero default
            default: begin
                imm = 32'd0;
            end
        endcase
    end

endmodule