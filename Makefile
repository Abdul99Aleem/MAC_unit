# Makefile for mac_unit — Vivado xvlog/xelab/xsim flow
# Vivado 2024.2 detected at /home/aleem/Vivado/2024.2

VIVADO_BIN := /home/aleem/Vivado/2024.2/bin

XVLOG  := $(VIVADO_BIN)/xvlog
XELAB  := $(VIVADO_BIN)/xelab
XSIM   := $(VIVADO_BIN)/xsim

TOP    := top_level_tb
SRCS   := mac_unit.v systolic_array_4x4.v top_level.v top_level_tb.v
MAC_TOP := mac_unit_tb
MAC_SRCS := mac_unit.v mac_unit_tb.v
SYS_TOP := system_verification_tb
SYS_SRCS := mac_unit.v systolic_array_4x4.v top_level.v system_verification_tb.v

.PHONY: all compile simulate simulate_mac simulate_system clean

all: simulate

compile:
	$(XVLOG) --sv $(SRCS)

simulate: compile
	$(XELAB) -debug typical $(TOP) -s $(TOP)_sim
	$(XSIM)  $(TOP)_sim --runall

simulate_mac:
	$(XVLOG) --sv $(MAC_SRCS)
	$(XELAB) -debug typical $(MAC_TOP) -s $(MAC_TOP)_sim
	$(XSIM)  $(MAC_TOP)_sim --runall

simulate_system:
	$(XVLOG) --sv $(SYS_SRCS)
	$(XELAB) -debug typical $(SYS_TOP) -s $(SYS_TOP)_sim
	$(XSIM)  $(SYS_TOP)_sim --runall

clean:
	rm -rf xvlog.log xelab.log xsim.log *.jou *.pb *.wdb \
	       xsim.dir .Xil webtalk*.log webtalk*.jou \
	       vivado*.log xsim*.log vivado_project/ usage_statistics_webtalk.*
