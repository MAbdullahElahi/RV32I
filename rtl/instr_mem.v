module instr_mem (
    input  [31:0] pc,
    output [31:0] instr
);
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        // Initialize all ROM slots to NOP (addi x0, x0, 0)
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013;

        // Relative path from project root (RV32I/)
        $readmemh("sw/compiled_hex/program.hex", mem);
    end

    assign instr = mem[pc[31:2]];
endmodule