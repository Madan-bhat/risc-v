module cpu #(
    parameter HEX = "mem/program.hex"
) (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] pc,
    output wire [31:0] instr,
    output wire [31:0] alu,
    output wire        we
);

    reg  [31:0] pc_r;
    wire [31:0] npc;
    wire [31:0] pc4 = pc_r + 32'd4;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_r <= 32'b0;
        else
            pc_r <= npc;
    end

    assign pc = pc_r;

    wire [31:0] ir;
    imem #(.FILE(HEX)) u_imem (
        .addr (pc_r),
        .data (ir)
    );
    assign instr = ir;

    wire [6:0] opcode = ir[6:0];
    wire [4:0] rd     = ir[11:7];
    wire [2:0] funct3 = ir[14:12];
    wire [4:0] rs1    = ir[19:15];
    wire [4:0] rs2    = ir[24:20];
    wire [6:0] funct7 = ir[31:25];

    wire       re, mwe, asrc, m2r, br, jal, jalr, lui, auipc;
    wire [2:0] isel;
    wire [3:0] aop;

    ctrl u_ctrl (
        .opcode (opcode),
        .funct3 (funct3),
        .funct7 (funct7),
        .we     (we),
        .re     (re),
        .mwe    (mwe),
        .asrc   (asrc),
        .m2r    (m2r),
        .br     (br),
        .jal    (jal),
        .jalr   (jalr),
        .lui    (lui),
        .auipc  (auipc),
        .isel   (isel),
        .aop    (aop)
    );

    wire [31:0] imm_v;
    imm u_imm (
        .instr (ir),
        .sel   (isel),
        .out   (imm_v)
    );

    wire [31:0] r1, r2, wd;

    regs u_regs (
        .clk (clk),
        .rst (rst),
        .we  (we),
        .rs1 (rs1),
        .rs2 (rs2),
        .rd  (rd),
        .wd  (wd),
        .r1  (r1),
        .r2  (r2)
    );

    wire [31:0] b = asrc ? imm_v : r2;
    wire [31:0] ay;
    wire        az;

    alu u_alu (
        .a    (r1),
        .b    (b),
        .op   (aop),
        .y    (ay),
        .zero (az)
    );
    assign alu = ay;

    wire [31:0] md;
    dmem u_dmem (
        .clk   (clk),
        .re    (re),
        .we    (mwe),
        .addr  (ay),
        .wdata (r2),
        .rdata (md)
    );

    assign wd = lui              ? imm_v :
                auipc            ? (pc_r + imm_v) :
                (jal | jalr)     ? pc4 :
                m2r              ? md :
                ay;

    reg taken;
    always @(*) begin
        case (funct3)
            3'b000:  taken = az;
            3'b001:  taken = ~az;
            3'b100:  taken = ay[0];
            3'b101:  taken = ~ay[0];
            3'b110:  taken = ay[0];
            3'b111:  taken = ~ay[0];
            default: taken = 1'b0;
        endcase
    end

    wire do_br = br & taken;
    wire [31:0] t_jalr = (r1 + imm_v) & 32'hFFFFFFFE;
    wire [31:0] t_br   = pc_r + imm_v;

    assign npc = jalr           ? t_jalr :
                 (jal | do_br)  ? t_br   :
                 pc4;

endmodule
