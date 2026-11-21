`timescale 1ns/1ps

module tb_reg_file;
    reg         clk, reg_write;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] rd_data;
    wire [31:0] rs1_data, rs2_data;

    integer pass_count = 0, fail_count = 0;

    reg_file uut (
        .clk       (clk),
        .reg_write (reg_write),
        .rs1       (rs1),
        .rs2       (rs2),
        .rd        (rd),
        .rd_data   (rd_data),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    always #5 clk = ~clk;

    task check_rf;
        input [127:0] name;
        input [4:0]   r1, r2;
        input [31:0]  exp1, exp2;
        begin
            rs1 = r1; rs2 = r2;
            #2;
            if (rs1_data === exp1 && rs2_data === exp2) begin
                $display("[PASS] %0s | x%0d=%h, x%0d=%h", name, r1, rs1_data, r2, rs2_data);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s | Got (%h, %h), Expected (%h, %h)", name, rs1_data, rs2_data, exp1, exp2);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        clk = 0; reg_write = 0; rs1 = 0; rs2 = 0; rd = 0; rd_data = 0;
        #10;

        // 1. Attempt write to x0 (must remain hardwired 0)
        @(negedge clk);
        reg_write = 1; rd = 5'd0; rd_data = 32'hDEAD_BEEF;
        @(posedge clk); #1;
        check_rf("x0 Hardwired Zero", 5'd0, 5'd0, 32'h0, 32'h0);

        // 2. Write x5 = 0x12345678
        @(negedge clk);
        rd = 5'd5; rd_data = 32'h1234_5678;
        @(posedge clk); #1;

        // 3. Write x10 = 0xAABBCCDD
        @(negedge clk);
        rd = 5'd10; rd_data = 32'hAABB_CCDD;
        @(posedge clk); #1;

        // 4. Dual async read check
        reg_write = 0;
        check_rf("Dual Read x5 & x10", 5'd5, 5'd10, 32'h1234_5678, 32'hAABB_CCDD);

        // 5. Write disabled check (x5 must not overwrite)
        @(negedge clk);
        reg_write = 0; rd = 5'd5; rd_data = 32'hFFFF_FFFF;
        @(posedge clk); #1;
        check_rf("RegWrite=0 Protection", 5'd5, 5'd0, 32'h1234_5678, 32'h0);

        $display("RegFile Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $stop;
    end
endmodule