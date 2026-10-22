module regs (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    output wire [31:0] r1,
    output wire [31:0] r2
);

    reg [31:0] r [0:31];
    integer i;

    assign r1 = (rs1 == 5'b0) ? 32'b0 : r[rs1];
    assign r2 = (rs2 == 5'b0) ? 32'b0 : r[rs2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                r[i] <= 32'b0;
        end else if (we && (rd != 5'b0)) begin
            r[rd] <= wd;
        end
    end

endmodule
