module alu (
    input  [31:0] a,          // Operand A (rs1_data or PC)
    input  [31:0] b,          // Operand B (rs2_data or sign-extended immediate)
    input  [3:0]  alu_ctrl,   // 4-bit operation selector from ALU Control
    output reg [31:0] result, // 32-bit computation output
    output        zero,       // High when result == 0 (for BEQ, BNE)
    output        lt,         // High when signed(a) < signed(b) (for BLT, BGE)
    output        ltu         // High when unsigned(a) < unsigned(b) (for BLTU, BGEU)
);

    // ALU Operation Encoding
    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_AND    = 4'b0010;
    localparam ALU_OR     = 4'b0011;
    localparam ALU_XOR    = 4'b0100;
    localparam ALU_SLT    = 4'b0101;
    localparam ALU_SLTU   = 4'b0110;
    localparam ALU_SLL    = 4'b0111;
    localparam ALU_SRL    = 4'b1000;
    localparam ALU_SRA    = 4'b1001;
    localparam ALU_PASS_B = 4'b1010;

    always @(*) begin
        // Default assignment guarantees zero inferred latches
        result = 32'd0;

        case (alu_ctrl)
            ALU_ADD:    result = a + b;                                      // ADD, ADDI, Load/Store addr, AUIPC
            ALU_SUB:    result = a - b;                                      // SUB, Branch comparisons
            ALU_AND:    result = a & b;                                      // AND, ANDI
            ALU_OR:     result = a | b;                                      // OR, ORI
            ALU_XOR:    result = a ^ b;                                      // XOR, XORI
            ALU_SLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;  // SLT, SLTI (Signed)
            ALU_SLTU:   result = (a < b) ? 32'd1 : 32'd0;                    // SLTU, SLTIU (Unsigned)
            ALU_SLL:    result = a << b[4:0];                                // SLL, SLLI (Logical Left)
            ALU_SRL:    result = a >> b[4:0];                                // SRL, SRLI (Logical Right)
            ALU_SRA:    result = $signed(a) >>> b[4:0];                      // SRA, SRAI (Arithmetic Right)
            ALU_PASS_B: result = b;                                          // LUI (Pass immediate directly)
            default:    result = 32'd0;
        endcase
    end

    // Status flags for conditional branch resolution
    assign zero = (result == 32'd0);
    assign lt   = ($signed(a) < $signed(b));
    assign ltu  = (a < b);

endmodule