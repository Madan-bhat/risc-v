module imm (
    input  wire [31:0] instr,
    input  wire [2:0]  sel,
    output reg  [31:0] out
);

    localparam I = 3'b000;
    localparam S = 3'b001;
    localparam B = 3'b010;
    localparam U = 3'b011;
    localparam J = 3'b100;

    always @(*) begin
        case (sel)
            I:       out = {{20{instr[31]}}, instr[31:20]};
            S:       out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            B:       out = {{19{instr[31]}}, instr[31], instr[7],
                            instr[30:25], instr[11:8], 1'b0};
            U:       out = {instr[31:12], 12'b0};
            J:       out = {{11{instr[31]}}, instr[31], instr[19:12],
                            instr[20], instr[30:21], 1'b0};
            default: out = 32'b0;
        endcase
    end

endmodule
