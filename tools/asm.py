#!/usr/bin/env python3
"""Minimal RV32I assembler for demo programs. Outputs Verilog $readmemh hex."""

import argparse
import re
import sys

REGS = {f"x{i}": i for i in range(32)}
REGS.update({
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7, "s0": 8, "fp": 8, "s1": 9,
    "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15,
    "a6": 16, "a7": 17, "s2": 18, "s3": 19, "s4": 20, "s5": 21,
    "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27,
    "t3": 28, "t4": 29, "t5": 30, "t6": 31,
})


def reg(name):
    name = name.strip().lower()
    if name not in REGS:
        raise ValueError(f"unknown register: {name}")
    return REGS[name]


def sext(val, bits):
    mask = (1 << bits) - 1
    val &= mask
    if val & (1 << (bits - 1)):
        val -= 1 << bits
    return val


def enc_r(funct7, rs2, rs1, funct3, rd, opcode):
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | \
           ((funct3 & 7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def enc_i(imm, rs1, funct3, rd, opcode):
    return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 7) << 12) | \
           ((rd & 0x1F) << 7) | (opcode & 0x7F)


def enc_s(imm, rs2, rs1, funct3, opcode):
    imm &= 0xFFF
    return (((imm >> 5) & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | \
           ((funct3 & 7) << 12) | ((imm & 0x1F) << 7) | (opcode & 0x7F)


def enc_b(imm, rs2, rs1, funct3, opcode):
    imm = sext(imm, 13) & 0x1FFF
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | \
           ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 7) << 12) | \
           (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | (opcode & 0x7F)


def enc_u(imm, rd, opcode):
    return (imm & 0xFFFFF000) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def enc_j(imm, rd, opcode):
    imm = sext(imm, 21) & 0x1FFFFF
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | \
           (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xFF) << 12) | \
           ((rd & 0x1F) << 7) | (opcode & 0x7F)


def parse_imm(tok, labels, pc):
    tok = tok.strip()
    if tok in labels:
        return labels[tok] - pc
    # label+const not needed
    if re.fullmatch(r"-?0x[0-9a-fA-F]+", tok):
        return int(tok, 16)
    if re.fullmatch(r"-?\d+", tok):
        return int(tok, 10)
    raise ValueError(f"bad immediate/label: {tok}")


def parse_mem(operand):
    # imm(rs1)
    m = re.fullmatch(r"(-?(?:0x[0-9a-fA-F]+|\d+))\(\s*(\w+)\s*\)", operand.strip())
    if not m:
        raise ValueError(f"bad mem operand: {operand}")
    imm = int(m.group(1), 0)
    return imm, reg(m.group(2))


def assemble(src):
    lines = []
    for raw in src.splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        lines.append(line)

    # Pass 1: labels
    labels = {}
    pc = 0
    ops = []
    for line in lines:
        if line.endswith(":"):
            labels[line[:-1].strip()] = pc
            continue
        # label: instr
        if ":" in line:
            lab, rest = line.split(":", 1)
            labels[lab.strip()] = pc
            line = rest.strip()
            if not line:
                continue
        ops.append((pc, line))
        pc += 4

    # Pass 2: encode
    words = []
    for pc, line in ops:
        parts = re.split(r"[,\s]+", line.strip())
        mnemonic = parts[0].lower()
        args = [a for a in parts[1:] if a]

        word = None
        if mnemonic == "addi":
            word = enc_i(parse_imm(args[2], labels, pc), reg(args[1]), 0, reg(args[0]), 0x13)
        elif mnemonic == "andi":
            word = enc_i(parse_imm(args[2], labels, pc), reg(args[1]), 7, reg(args[0]), 0x13)
        elif mnemonic == "ori":
            word = enc_i(parse_imm(args[2], labels, pc), reg(args[1]), 6, reg(args[0]), 0x13)
        elif mnemonic == "xori":
            word = enc_i(parse_imm(args[2], labels, pc), reg(args[1]), 4, reg(args[0]), 0x13)
        elif mnemonic == "slti":
            word = enc_i(parse_imm(args[2], labels, pc), reg(args[1]), 2, reg(args[0]), 0x13)
        elif mnemonic == "sltiu":
            word = enc_i(parse_imm(args[2], labels, pc), reg(args[1]), 3, reg(args[0]), 0x13)
        elif mnemonic == "slli":
            word = enc_i(parse_imm(args[2], labels, pc) & 0x1F, reg(args[1]), 1, reg(args[0]), 0x13)
        elif mnemonic == "srli":
            word = enc_i(parse_imm(args[2], labels, pc) & 0x1F, reg(args[1]), 5, reg(args[0]), 0x13)
        elif mnemonic == "srai":
            word = enc_i(0x400 | (parse_imm(args[2], labels, pc) & 0x1F), reg(args[1]), 5, reg(args[0]), 0x13)
        elif mnemonic == "add":
            word = enc_r(0, reg(args[2]), reg(args[1]), 0, reg(args[0]), 0x33)
        elif mnemonic == "sub":
            word = enc_r(0x20, reg(args[2]), reg(args[1]), 0, reg(args[0]), 0x33)
        elif mnemonic == "and":
            word = enc_r(0, reg(args[2]), reg(args[1]), 7, reg(args[0]), 0x33)
        elif mnemonic == "or":
            word = enc_r(0, reg(args[2]), reg(args[1]), 6, reg(args[0]), 0x33)
        elif mnemonic == "xor":
            word = enc_r(0, reg(args[2]), reg(args[1]), 4, reg(args[0]), 0x33)
        elif mnemonic == "sll":
            word = enc_r(0, reg(args[2]), reg(args[1]), 1, reg(args[0]), 0x33)
        elif mnemonic == "srl":
            word = enc_r(0, reg(args[2]), reg(args[1]), 5, reg(args[0]), 0x33)
        elif mnemonic == "sra":
            word = enc_r(0x20, reg(args[2]), reg(args[1]), 5, reg(args[0]), 0x33)
        elif mnemonic == "slt":
            word = enc_r(0, reg(args[2]), reg(args[1]), 2, reg(args[0]), 0x33)
        elif mnemonic == "sltu":
            word = enc_r(0, reg(args[2]), reg(args[1]), 3, reg(args[0]), 0x33)
        elif mnemonic == "lui":
            imm = parse_imm(args[1], labels, pc)
            word = enc_u(imm << 12 if abs(imm) < 0x100000 else imm, reg(args[0]), 0x37)
        elif mnemonic == "auipc":
            imm = parse_imm(args[1], labels, pc)
            word = enc_u(imm << 12 if abs(imm) < 0x100000 else imm, reg(args[0]), 0x17)
        elif mnemonic == "lw":
            imm, rs1 = parse_mem(args[1])
            word = enc_i(imm, rs1, 2, reg(args[0]), 0x03)
        elif mnemonic == "sw":
            imm, rs1 = parse_mem(args[1])
            word = enc_s(imm, reg(args[0]), rs1, 2, 0x23)
        elif mnemonic == "beq":
            word = enc_b(parse_imm(args[2], labels, pc), reg(args[1]), reg(args[0]), 0, 0x63)
        elif mnemonic == "bne":
            word = enc_b(parse_imm(args[2], labels, pc), reg(args[1]), reg(args[0]), 1, 0x63)
        elif mnemonic == "blt":
            word = enc_b(parse_imm(args[2], labels, pc), reg(args[1]), reg(args[0]), 4, 0x63)
        elif mnemonic == "bge":
            word = enc_b(parse_imm(args[2], labels, pc), reg(args[1]), reg(args[0]), 5, 0x63)
        elif mnemonic == "bltu":
            word = enc_b(parse_imm(args[2], labels, pc), reg(args[1]), reg(args[0]), 6, 0x63)
        elif mnemonic == "bgeu":
            word = enc_b(parse_imm(args[2], labels, pc), reg(args[1]), reg(args[0]), 7, 0x63)
        elif mnemonic == "jal":
            if len(args) == 1:
                word = enc_j(parse_imm(args[0], labels, pc), 0, 0x6F)
            else:
                word = enc_j(parse_imm(args[1], labels, pc), reg(args[0]), 0x6F)
        elif mnemonic == "jalr":
            if len(args) == 1:
                # jalr rs1  -> jalr x1, 0(rs1)  (pseudo varies; use rd, rs1, imm)
                word = enc_i(0, reg(args[0]), 0, 1, 0x67)
            elif "(" in args[1]:
                imm, rs1 = parse_mem(args[1])
                word = enc_i(imm, rs1, 0, reg(args[0]), 0x67)
            else:
                word = enc_i(parse_imm(args[2], labels, pc), reg(args[1]), 0, reg(args[0]), 0x67)
        elif mnemonic == "nop":
            word = enc_i(0, 0, 0, 0, 0x13)
        elif mnemonic == "j":
            word = enc_j(parse_imm(args[0], labels, pc), 0, 0x6F)
        else:
            raise ValueError(f"unsupported mnemonic: {mnemonic}")

        words.append(word & 0xFFFFFFFF)

    return words


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("-o", "--output", required=True)
    ap.add_argument("--pad", type=int, default=256,
                    help="Pad hex to this many words (NOP=addi x0,x0,0)")
    args = ap.parse_args()

    with open(args.src) as f:
        words = assemble(f.read())

    nop = 0x00000013
    while len(words) < args.pad:
        words.append(nop)

    with open(args.output, "w") as f:
        for w in words:
            f.write(f"{w:08x}\n")
    print(f"Wrote {len(words)} words to {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
