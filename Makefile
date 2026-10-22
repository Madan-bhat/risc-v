IVERILOG ?= iverilog
VVP      ?= vvp
PYTHON   ?= python3

RTL = rtl/alu.v rtl/regs.v rtl/imm.v rtl/ctrl.v rtl/imem.v rtl/dmem.v rtl/cpu.v
TB  = tb/tb_cpu.v

.PHONY: all hex sim clean

all: sim

hex: mem/program.hex

mem/program.hex: mem/program.s tools/asm.py
	$(PYTHON) tools/asm.py mem/program.s -o mem/program.hex

sim: mem/program.hex
	$(IVERILOG) -g2001 -o sim.vvp $(RTL) $(TB)
	$(VVP) sim.vvp

clean:
	rm -f sim.vvp tb_cpu.vcd mem/program.hex
