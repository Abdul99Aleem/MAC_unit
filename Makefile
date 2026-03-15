# Makefile for mac_unit — Vivado xvlog/xelab/xsim flow
# Vivado 2024.2 detected at /home/aleem/Vivado/2024.2

VIVADO_BIN := /home/aleem/Vivado/2024.2/bin

XVLOG  := $(VIVADO_BIN)/xvlog
XELAB  := $(VIVADO_BIN)/xelab
XSIM   := $(VIVADO_BIN)/xsim

TOP    := mac_unit_tb
SRCS   := mac_unit.v mac_unit_tb.v

.PHONY: all compile simulate clean

all: simulate

compile:
	$(XVLOG) --sv $(SRCS)

simulate: compile
	$(XELAB) -debug typical $(TOP) -s $(TOP)_sim
	$(XSIM)  $(TOP)_sim --runall

clean:
	rm -rf xvlog.log xelab.log xsim.log *.jou *.pb \
	       xsim.dir .Xil webtalk*.log webtalk*.jou
