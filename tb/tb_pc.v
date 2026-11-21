`timescale 1ns/1ps

module tb_pc;
    reg         clk, rst;
    reg  [31:0] pc_next;
    wire [31:0] pc_current;

    integer pass_count = 0, fail_count = 0;

    pc uut (
        .clk        (clk),
        .rst        (rst),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    always #5 clk = ~clk;

    task check_pc;
        input [127:0] name;
        input [31:0]  exp;
        begin
            #1;
            if (pc_current === exp) begin
                $display("[PASS] %0s | pc_current = %h", name, pc_current);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s | Got %h, Expected %h", name, pc_current, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        clk = 0; rst = 1; pc_next = 32'h0000_0004;
        #3; check_pc("Async Reset", 32'h0000_0000);

        @(negedge clk); rst = 0;
        @(posedge clk); check_pc("Update to 0x04", 32'h0000_0004);

        pc_next = 32'h0000_0008;
        @(posedge clk); check_pc("Update to 0x08", 32'h0000_0008);

        pc_next = 32'h0000_0040;
        @(posedge clk); check_pc("Branch Jump 0x40", 32'h0000_0040);

        rst = 1;
        #2; check_pc("Mid-cycle Reset", 32'h0000_0000);

        $display("PC Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $stop;
    end
endmodule