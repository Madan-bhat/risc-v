module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  op,
    output reg  [31:0] y,
    output wire        zero
);

    localparam ADD  = 4'b0000;
    localparam SUB  = 4'b0001;
    localparam AND  = 4'b0010;
    localparam OR   = 4'b0011;
    localparam XOR  = 4'b0100;
    localparam SLT  = 4'b0101;
    localparam SLTU = 4'b0110;
    localparam SLL  = 4'b0111;
    localparam SRL  = 4'b1000;
    localparam SRA  = 4'b1001;

    assign zero = (y == 32'b0);

    always @(*) begin
        case (op)
            ADD:     y = a + b;
            SUB:     y = a - b;
            AND:     y = a & b;
            OR:      y = a | b;
            XOR:     y = a ^ b;
            SLT:     y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            SLTU:    y = (a < b) ? 32'd1 : 32'd0;
            SLL:     y = a << b[4:0];
            SRL:     y = a >> b[4:0];
            SRA:     y = $signed(a) >>> b[4:0];
            default: y = 32'b0;
        endcase
    end

endmodule
