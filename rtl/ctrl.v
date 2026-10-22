module ctrl (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        we,
    output reg        re,
    output reg        mwe,
    output reg        asrc,
    output reg        m2r,
    output reg        br,
    output reg        jal,
    output reg        jalr,
    output reg        lui,
    output reg        auipc,
    output reg [2:0]  isel,
    output reg [3:0]  aop
);

    localparam OP_LUI  = 7'b0110111;
    localparam OP_AUI  = 7'b0010111;
    localparam OP_JAL  = 7'b1101111;
    localparam OP_JALR = 7'b1100111;
    localparam OP_BR   = 7'b1100011;
    localparam OP_LD   = 7'b0000011;
    localparam OP_ST   = 7'b0100011;
    localparam OP_IMM  = 7'b0010011;
    localparam OP_REG  = 7'b0110011;

    localparam I = 3'b000;
    localparam S = 3'b001;
    localparam B = 3'b010;
    localparam U = 3'b011;
    localparam J = 3'b100;

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

    always @(*) begin
        we    = 1'b0;
        re    = 1'b0;
        mwe   = 1'b0;
        asrc  = 1'b0;
        m2r   = 1'b0;
        br    = 1'b0;
        jal   = 1'b0;
        jalr  = 1'b0;
        lui   = 1'b0;
        auipc = 1'b0;
        isel  = I;
        aop   = ADD;

        case (opcode)
            OP_LUI: begin
                we   = 1'b1;
                lui  = 1'b1;
                isel = U;
            end

            OP_AUI: begin
                we    = 1'b1;
                auipc = 1'b1;
                isel  = U;
                aop   = ADD;
            end

            OP_JAL: begin
                we   = 1'b1;
                jal  = 1'b1;
                isel = J;
            end

            OP_JALR: begin
                we   = 1'b1;
                jalr = 1'b1;
                asrc = 1'b1;
                isel = I;
                aop  = ADD;
            end

            OP_BR: begin
                br   = 1'b1;
                isel = B;
                case (funct3)
                    3'b000, 3'b001: aop = SUB;
                    3'b100, 3'b101: aop = SLT;
                    3'b110, 3'b111: aop = SLTU;
                    default:        aop = SUB;
                endcase
            end

            OP_LD: begin
                we   = 1'b1;
                re   = 1'b1;
                asrc = 1'b1;
                m2r  = 1'b1;
                isel = I;
                aop  = ADD;
            end

            OP_ST: begin
                mwe  = 1'b1;
                asrc = 1'b1;
                isel = S;
                aop  = ADD;
            end

            OP_IMM: begin
                we   = 1'b1;
                asrc = 1'b1;
                isel = I;
                case (funct3)
                    3'b000:  aop = ADD;
                    3'b010:  aop = SLT;
                    3'b011:  aop = SLTU;
                    3'b100:  aop = XOR;
                    3'b110:  aop = OR;
                    3'b111:  aop = AND;
                    3'b001:  aop = SLL;
                    3'b101:  aop = funct7[5] ? SRA : SRL;
                    default: aop = ADD;
                endcase
            end

            OP_REG: begin
                we = 1'b1;
                case (funct3)
                    3'b000:  aop = funct7[5] ? SUB : ADD;
                    3'b001:  aop = SLL;
                    3'b010:  aop = SLT;
                    3'b011:  aop = SLTU;
                    3'b100:  aop = XOR;
                    3'b101:  aop = funct7[5] ? SRA : SRL;
                    3'b110:  aop = OR;
                    3'b111:  aop = AND;
                    default: aop = ADD;
                endcase
            end

            default: begin
            end
        endcase
    end

endmodule
