# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

8-bit signed MAC (Multiply-Accumulate) unit in Verilog, targeting Xilinx Zynq FPGA for use in a 4x4 systolic array. Simulated with Vivado 2024.2 (installed at `/home/aleem/Vivado/2024.2`).

## Simulation Commands

```bash
make compile       # xvlog: parse + elaborate
make simulate      # compile + xelab + xsim (full run)
make clean         # remove all Vivado-generated artifacts
```

Run a single simulation manually:
```bash
/home/aleem/Vivado/2024.2/bin/xvlog mac_unit.v mac_unit_tb.v
/home/aleem/Vivado/2024.2/bin/xelab -debug typical mac_unit_tb -s mac_unit_tb_sim
/home/aleem/Vivado/2024.2/bin/xsim mac_unit_tb_sim --runall
```

## Architecture

- **`mac_unit.v`** — single pipeline stage: `acc_out <= acc_in + (a * b)` on rising edge with synchronous active-low reset. Synthesizes to a DSP48 slice on Zynq.
- **`mac_unit_tb.v`** — self-checking testbench; feeds inputs one cycle before checking `acc_out` (registered output). Prints `PASS/FAIL` per case and calls `$finish`.

## Key Conventions

- Non-blocking assignments (`<=`) everywhere in `always @(posedge clk)` blocks.
- All ports and internal signals declared `signed` explicitly — Verilog does not propagate signedness automatically.
- `acc_out` is registered, so testbench checks the output one clock cycle after applying inputs.
- The `signed` keyword on `wire`/`reg` declarations is required; without it, multiplication and comparison treat values as unsigned.
