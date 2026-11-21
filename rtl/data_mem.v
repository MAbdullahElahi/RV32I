module data_mem (
    input             clk,
    input             mem_read,
    input             mem_write,
    input      [2:0]  funct3,     // instr[14:12]: distinguishes byte, halfword, word, signed/unsigned
    input      [31:0] addr,       // Byte address computed by ALU (rs1 + imm)
    input      [31:0] write_data, // rs2_data to store
    output reg [31:0] read_data   // Loaded 32-bit word (sign- or zero-extended)
);
    // 256 x 32-bit words = 1024 bytes (1 KB) of little-endian data memory
    reg [31:0] dmem [0:255];

    // Word index and selected 32-bit word from byte address
    wire [7:0]  word_addr = addr[9:2];
    wire [31:0] word_data = dmem[word_addr];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            dmem[i] = 32'h00000000;
    end

    // =========================================================================
    // 1. SYNCHRONOUS WRITE LOGIC (SB, SH, SW) - Little-Endian Byte-Lane Masking
    // =========================================================================
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB (Store Byte: writes write_data[7:0] into 1 of 4 byte lanes)
                    case (addr[1:0])
                        2'b00: dmem[word_addr][7:0]   <= write_data[7:0]; // Byte 0 (LSB)
                        2'b01: dmem[word_addr][15:8]  <= write_data[7:0]; // Byte 1
                        2'b10: dmem[word_addr][23:16] <= write_data[7:0]; // Byte 2
                        2'b11: dmem[word_addr][31:24] <= write_data[7:0]; // Byte 3 (MSB)
                    endcase
                end

                3'b001: begin // SH (Store Halfword: writes write_data[15:0] into lower or upper 16 bits)
                    case (addr[1])
                        1'b0: dmem[word_addr][15:0]  <= write_data[15:0]; // Halfword 0 (bytes 1..0)
                        1'b1: dmem[word_addr][31:16] <= write_data[15:0]; // Halfword 1 (bytes 3..2)
                    endcase
                end

                3'b010: begin // SW (Store Word: writes all 32 bits)
                    dmem[word_addr] <= write_data;
                end

                default: ; // Do nothing for invalid store funct3
            endcase
        end
    end

    // =========================================================================
    // 2. ASYNCHRONOUS READ LOGIC (LB, LH, LW, LBU, LHU) - Zero Inferred Latches
    // =========================================================================
    always @(*) begin
        // Default assignment prevents inferred latches
        read_data = 32'd0;

        if (mem_read) begin
            case (funct3)
                3'b000: begin // LB (Load Byte - Signed: replicate bit 7 of selected byte 24 times)
                    case (addr[1:0])
                        2'b00: read_data = {{24{word_data[7]}},  word_data[7:0]};
                        2'b01: read_data = {{24{word_data[15]}}, word_data[15:8]};
                        2'b10: read_data = {{24{word_data[23]}}, word_data[23:16]};
                        2'b11: read_data = {{24{word_data[31]}}, word_data[31:24]};
                    endcase
                end

                3'b001: begin // LH (Load Halfword - Signed: replicate bit 15 of selected halfword 16 times)
                    case (addr[1])
                        1'b0: read_data = {{16{word_data[15]}}, word_data[15:0]};
                        1'b1: read_data = {{16{word_data[31]}}, word_data[31:16]};
                    endcase
                end

                3'b010: begin // LW (Load Word - Full 32 bits)
                    read_data = word_data;
                end

                3'b100: begin // LBU (Load Byte - Unsigned: zero-extend upper 24 bits)
                    case (addr[1:0])
                        2'b00: read_data = {24'd0, word_data[7:0]};
                        2'b01: read_data = {24'd0, word_data[15:8]};
                        2'b10: read_data = {24'd0, word_data[23:16]};
                        2'b11: read_data = {24'd0, word_data[31:24]};
                    endcase
                end

                3'b101: begin // LHU (Load Halfword - Unsigned: zero-extend upper 16 bits)
                    case (addr[1])
                        1'b0: read_data = {16'd0, word_data[15:0]};
                        1'b1: read_data = {16'd0, word_data[31:16]};
                    endcase
                end

                default: read_data = 32'd0;
            endcase
        end
    end

endmodule