`timescale 1ns/1ps

module tb_mux;
    reg  [31:0] a, b;
    reg         sel;
    wire [31:0] y;

    integer pass_count = 0, fail_count = 0;

    mux2 uut (.a(a), .b(b), .sel(sel), .y(y));

    initial begin
        a = 32'h1111_2222; b = 32'hAAAA_BBBB;

        sel = 1'b0; #5;
        if (y === a) begin $display("[PASS] sel=0 -> y=%h", y); pass_count = pass_count + 1; end
        else         begin $display("[FAIL] sel=0 -> Got %h, Exp %h", y, a); fail_count = fail_count + 1; end

        sel = 1'b1; #5;
        if (y === b) begin $display("[PASS] sel=1 -> y=%h", y); pass_count = pass_count + 1; end
        else         begin $display("[FAIL] sel=1 -> Got %h, Exp %h", y, b); fail_count = fail_count + 1; end

        $display("Mux2 Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $stop;
    end
endmodule