module core_top (
    input clk,
    input rst
);
    // Program Counter & Instruction Fetch wires
    wire [31:0] pc_current, pc_next, pc_plus_4, pc_target, jalr_target;
    wire [31:0] instr;

    // Register File & Immediate wires
    wire [31:0] rs1_data, rs2_data, rd_data;
    wire [31:0] imm;

    // ALU wires
    wire [31:0] alu_a, alu_b, alu_result;
    wire        zero, lt, ltu;
    reg  [3:0]  alu_ctrl;

    // Data Memory wire
    wire [31:0] mem_rd;

    // Main Control signals
    wire        branch, jump, jalr;
    wire        mem_read, mem_write;
    wire [1:0]  result_src;
    wire [2:0]  alu_op;
    wire        alu_src_a, alu_src_b;
    wire        reg_write;

    // Branch & Jump resolution signals
    reg         branch_cond;
    wire        take_branch_or_jal;

    // ALU Operation Encodings (matching alu.v)
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

    // =========================================================================
    // 1. FETCH STAGE (PC, Adder, Branch/Jump Target Mux, Instruction Memory)
    // =========================================================================
    assign pc_plus_4   = pc_current + 32'd4;
    assign pc_target   = pc_current + imm;              // For B-type branches & J-type JAL
    assign jalr_target = {alu_result[31:1], 1'b0};      // For JALR: (rs1 + imm) & ~1

    // Evaluate all 6 RV32I conditional branches using funct3 (instr[14:12])
    always @(*) begin
        branch_cond = 1'b0;
        case (instr[14:12])
            3'b000:  branch_cond = zero;   // BEQ:  rs1 == rs2
            3'b001:  branch_cond = ~zero;  // BNE:  rs1 != rs2
            3'b100:  branch_cond = lt;     // BLT:  signed(rs1) < signed(rs2)
            3'b101:  branch_cond = ~lt;    // BGE:  signed(rs1) >= signed(rs2)
            3'b110:  branch_cond = ltu;    // BLTU: unsigned(rs1) < unsigned(rs2)
            3'b111:  branch_cond = ~ltu;   // BGEU: unsigned(rs1) >= unsigned(rs2)
            default: branch_cond = 1'b0;
        endcase
    end

    assign take_branch_or_jal = (branch & branch_cond) | jump;

    // Next PC Selection: Priority -> JALR > (Taken Branch or JAL) > PC+4
    assign pc_next = jalr               ? jalr_target :
                     take_branch_or_jal ? pc_target   :
                                          pc_plus_4;

    pc pc_inst (
        .clk        (clk),
        .rst        (rst),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    instr_mem imem (
        .pc    (pc_current),
        .instr (instr)
    );

    // =========================================================================
    // 2. DECODE STAGE (Control Unit, Register File, Immediate Generator)
    // =========================================================================
    control ctrl (
        .opcode     (instr[6:0]),
        .branch     (branch),
        .jump       (jump),
        .jalr       (jalr),
        .mem_read   (mem_read),
        .result_src (result_src),
        .alu_op     (alu_op),
        .mem_write  (mem_write),
        .alu_src_a  (alu_src_a),
        .alu_src_b  (alu_src_b),
        .reg_write  (reg_write)
    );

    reg_file rf (
        .clk       (clk),
        .reg_write (reg_write),
        .rs1       (instr[19:15]),
        .rs2       (instr[24:20]),
        .rd        (instr[11:7]),
        .rd_data   (rd_data),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    imm_gen ig (
        .instr (instr),
        .imm   (imm)
    );

    // =========================================================================
    // 3. EXECUTE STAGE (Operand Muxes, Full RV32I ALU Decoder, ALU)
    // =========================================================================
    mux2 alu_mux_a (
        .a   (rs1_data),
        .b   (pc_current),
        .sel (alu_src_a),
        .y   (alu_a)
    );

    mux2 alu_mux_b (
        .a   (rs2_data),
        .b   (imm),
        .sel (alu_src_b),
        .y   (alu_b)
    );

    // Secondary ALU Control Decoder (zero inferred latches)
    always @(*) begin
        alu_ctrl = ALU_ADD; // Default: ALU_ADD

        case (alu_op)
            3'b000: alu_ctrl = ALU_ADD;    // ADD (Load, Store, AUIPC, JALR)
            3'b001: alu_ctrl = ALU_SUB;    // SUB (Branch comparisons)
            3'b100: alu_ctrl = ALU_PASS_B; // PASS_B (LUI)

            3'b010: begin                  // R-Type ALU (opcode 7'h33)
                case (instr[14:12])
                    3'b000:  alu_ctrl = (instr[31:25] == 7'b0100000) ? ALU_SUB : ALU_ADD;
                    3'b001:  alu_ctrl = ALU_SLL;
                    3'b010:  alu_ctrl = ALU_SLT;
                    3'b011:  alu_ctrl = ALU_SLTU;
                    3'b100:  alu_ctrl = ALU_XOR;
                    3'b101:  alu_ctrl = (instr[31:25] == 7'b0100000) ? ALU_SRA : ALU_SRL;
                    3'b110:  alu_ctrl = ALU_OR;
                    3'b111:  alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            3'b011: begin                  // I-Type ALU (opcode 7'h13)
                case (instr[14:12])
                    3'b000:  alu_ctrl = ALU_ADD;  // ADDI (ignores upper bits)
                    3'b001:  alu_ctrl = (instr[31:25] == 7'b0000000) ? ALU_SLL : ALU_ADD; // SLLI
                    3'b010:  alu_ctrl = ALU_SLT;  // SLTI
                    3'b011:  alu_ctrl = ALU_SLTU; // SLTIU
                    3'b100:  alu_ctrl = ALU_XOR;  // XORI
                    3'b101:  alu_ctrl = (instr[31:25] == 7'b0100000) ? ALU_SRA :
                                        (instr[31:25] == 7'b0000000) ? ALU_SRL : ALU_ADD;
                    3'b110:  alu_ctrl = ALU_OR;   // ORI
                    3'b111:  alu_ctrl = ALU_AND;  // ANDI
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            default: alu_ctrl = ALU_ADD;
        endcase
    end

    alu alu_inst (
        .a        (alu_a),
        .b        (alu_b),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result),
        .zero     (zero),
        .lt       (lt),
        .ltu      (ltu)
    );

    // =========================================================================
    // 4. MEMORY STAGE (Data Memory with funct3 for Byte/Halfword/Word)
    // =========================================================================
    data_mem dmem (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .funct3     (instr[14:12]),
        .addr       (alu_result),
        .write_data (rs2_data),
        .read_data  (mem_rd)
    );

    // =========================================================================
    // 5. WRITE-BACK STAGE (3-to-1 Result Mux: ALU, Data Memory, or PC+4)
    // =========================================================================
    assign rd_data = (result_src == 2'b01) ? mem_rd    :
                     (result_src == 2'b10) ? pc_plus_4 :
                                             alu_result;

endmodule