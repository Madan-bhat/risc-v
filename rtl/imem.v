module imem #(
    parameter DEPTH = 256,
    parameter FILE  = ""
) (
    input  wire [31:0] addr,
    output wire [31:0] data
);

    reg [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h00000013;
        if (FILE != "")
            $readmemh(FILE, mem);
    end

    assign data = mem[addr[31:2]];

endmodule
