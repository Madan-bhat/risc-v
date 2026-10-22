# Single-cycle RV32I processor (pure Verilog)

A teaching-oriented **RISC-V RV32I** CPU written in **IEEE 1364-2001 Verilog** (not SystemVerilog).

## Architecture

Single-cycle datapath: one instruction completes every clock cycle.

```
   PC → IMEM → decode → regfile → ALU → DMEM → writeback
                ↓                    ↑
              imm_gen ───────────────┘
                ↓
           next-PC (branch / JAL / JALR)
```

| Module | Role |
|--------|------|
| `rtl/cpu.v` | Top-level datapath + PC |
| `rtl/alu.v` | ADD/SUB/AND/OR/XOR/SLT/SLTU/SLL/SRL/SRA |
| `rtl/regfile.v` | 32×32 registers (`x0` hardwired 0) |
| `rtl/imm_gen.v` | I/S/B/U/J immediates |
| `rtl/control.v` | Opcode/funct decode |
| `rtl/instr_mem.v` | Instruction ROM (`$readmemh`) |
| `rtl/data_mem.v` | Word-addressed data RAM |

## Supported instructions

- **R:** `ADD SUB AND OR XOR SLT SLTU SLL SRL SRA`
- **I:** `ADDI ANDI ORI XORI SLTI SLTIU SLLI SRLI SRAI LW JALR`
- **S:** `SW`
- **B:** `BEQ BNE BLT BGE BLTU BGEU`
- **U:** `LUI AUIPC`
- **J:** `JAL`

Loads/stores are **word-only** (`LW`/`SW`) in this subset.

## Quick start

Needs [Icarus Verilog](https://steveicarus.github.io/iverilog/) and Python 3.

```bash
# macOS
brew install icarus-verilog

make sim
```

Expected output ends with:

```text
PASS: sum 1..10 = 55 (mem[0]) after ... cycles
```

A VCD waveform is written to `tb_cpu.vcd` (view with GTKWave).

## Demo program

`mem/program.s` sums `1..10` into `x2`, stores the result at data address `0`, then hangs:

```asm
addi x2, x0, 0
addi x1, x0, 1
addi x3, x0, 11
loop:
  beq  x1, x3, done
  add  x2, x2, x1
  addi x1, x1, 1
  j    loop
done:
  sw   x2, 0(x0)
hang:
  j    hang
```

Assemble only:

```bash
make hex   # → mem/program.hex
```

## Layout

```text
rtl/          CPU Verilog sources
tb/           Testbench
mem/          Assembly + generated hex
tools/asm.py  Tiny RV32I assembler
Makefile
```
