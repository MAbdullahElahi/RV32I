module reg_file (
    input clk,
    input reg_write,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] rd_data,
    output [31:0] rs1_data,
    output [31:0] rs2_data
);
    reg [31:0] rf [31:0];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            rf[i] = 32'h0;
    end

    always @(posedge clk) begin
        if (reg_write && (rd != 5'd0))
            rf[rd] <= rd_data;
    end

    assign rs1_data = (rs1 == 5'd0) ? 32'h0 : rf[rs1];
    assign rs2_data = (rs2 == 5'd0) ? 32'h0 : rf[rs2];
endmodule