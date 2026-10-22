module dmem #(
    parameter DEPTH = 256
) (
    input  wire        clk,
    input  wire        re,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);

    reg [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;
    end

    assign rdata = re ? mem[addr[31:2]] : 32'b0;

    always @(posedge clk) begin
        if (we)
            mem[addr[31:2]] <= wdata;
    end

endmodule
