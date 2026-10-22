`timescale 1ns / 1ps

module tb_cpu;

    reg         clk;
    reg         rst;
    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] alu;
    wire        we;

    cpu #(.HEX("mem/program.hex")) dut (
        .clk   (clk),
        .rst   (rst),
        .pc    (pc),
        .instr (instr),
        .alu   (alu),
        .we    (we)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer cycle;
    integer pass;

    initial begin
        $dumpfile("tb_cpu.vcd");
        $dumpvars(0, tb_cpu);

        rst   = 1'b1;
        cycle = 0;
        pass  = 0;

        repeat (4) @(posedge clk);
        rst = 1'b0;

        repeat (200) begin
            @(posedge clk);
            cycle = cycle + 1;

            if (pc == 32'h00000020) begin
                @(posedge clk);
                if (dut.u_dmem.mem[0] === 32'd55) begin
                    $display("PASS: sum 1..10 = %0d (mem[0]) after %0d cycles",
                             dut.u_dmem.mem[0], cycle);
                    pass = 1;
                end else begin
                    $display("FAIL: expected mem[0]=55, got %0d", dut.u_dmem.mem[0]);
                end
                $display("Registers: x1=%0d x2=%0d x3=%0d",
                         dut.u_regs.r[1], dut.u_regs.r[2], dut.u_regs.r[3]);
                if (pass)
                    $finish;
                else
                    $fatal(1, "CPU test failed");
            end
        end

        $display("FAIL: timeout. PC=%h instr=%h mem[0]=%0d",
                 pc, instr, dut.u_dmem.mem[0]);
        $fatal(1, "timeout");
    end

    always @(posedge clk) begin
        if (!rst)
            $display("t=%0t PC=%h INSTR=%h ALU=%h", $time, pc, instr, alu);
    end

endmodule
