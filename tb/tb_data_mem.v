`timescale 1ns/1ps

module tb_data_mem;
    reg         clk, mem_read, mem_write;
    reg  [2:0]  funct3;
    reg  [31:0] addr, write_data;
    wire [31:0] read_data;

    integer pass_count = 0, fail_count = 0;

    data_mem uut (
        .clk(clk), .mem_read(mem_read), .mem_write(mem_write),
        .funct3(funct3), .addr(addr), .write_data(write_data), .read_data(read_data)
    );

    always #5 clk = ~clk;

    task check_load;
        input [127:0] name;
        input [2:0]   f3;
        input [31:0]  a, exp;
        begin
            mem_write = 0; mem_read = 1; funct3 = f3; addr = a; #2;
            if (read_data === exp) begin
                $display("[PASS] %0s -> %h", name, read_data);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s -> Got %h, Exp %h", name, read_data, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        clk = 0; mem_read = 0; mem_write = 0; funct3 = 0; addr = 0; write_data = 0;

        // 1. SW 0x80F0_7F01 at addr 0x00
        @(negedge clk); mem_write = 1; funct3 = 3'b010; addr = 32'h00; write_data = 32'h80F0_7F01;
        @(posedge clk); #1;
        check_load("LW",  3'b010, 32'h00, 32'h80F0_7F01);
        check_load("LB (byte 2 = 0xF0 -> sign-ext)",  3'b000, 32'h02, 32'hFFFF_FFF0);
        check_load("LBU (byte 2 = 0xF0 -> zero-ext)", 3'b100, 32'h02, 32'h0000_00F0);
        check_load("LH (upper half = 0x80F0 -> sign)",3'b001, 32'h02, 32'hFFFF_80F0);
        check_load("LHU (upper half = 0x80F0 -> zero)",3'b101, 32'h02, 32'h0000_80F0);

        // 2. SB 0xAA into byte lane 1 (addr 0x01) -> word becomes 0x80F0_AA01
        @(negedge clk); mem_read = 0; mem_write = 1; funct3 = 3'b000; addr = 32'h01; write_data = 32'h0000_00AA;
        @(posedge clk); #1;
        check_load("LW after SB", 3'b010, 32'h00, 32'h80F0_AA01);

        // 3. SH 0x1234 into upper halfword (addr 0x02) -> word becomes 0x1234_AA01
        @(negedge clk); mem_read = 0; mem_write = 1; funct3 = 3'b001; addr = 32'h02; write_data = 32'h0000_1234;
        @(posedge clk); #1;
        check_load("LW after SH", 3'b010, 32'h00, 32'h1234_AA01);

        $display("DataMem Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $stop;
    end
endmodule