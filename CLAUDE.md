# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

8-bit signed MAC (Multiply-Accumulate) unit in Verilog, targeting Xilinx Zynq FPGA for use in a 4x4 systolic array. Simulated with Vivado 2024.2 (installed at `/home/aleem/Vivado/2024.2`).

## Build & Synthesis Commands

```bash
make compile       # xvlog: parse + elaborate
make simulate      # compile + xelab + xsim (full run)
make clean         # remove all Vivado-generated artifacts
vivado -mode batch -source create_project.tcl  # Automated Vivado project creation and synthesis
```

## Architecture

- **`top_level.v`** — AXI4-Lite wrapper for the systolic array. Register map: Inputs (0x00-0x1C), Results (0x20-0x5C), Control/Status (0xA0).
- **`mac_unit.v`** — single pipeline stage: `acc_out <= acc_in + (a * b)` on rising edge with synchronous active-low reset. Synthesizes to a DSP48 slice on Zynq (use `(* use_dsp = "yes" *)` attribute).
- **`systolic_array_4x4.v`** — 4x4 grid with internal propagation and skewing logic.
- **`top_level_tb.v`** — AXI-level testbench for verifying the full SoC integration.

## Key Conventions

- Non-blocking assignments (`<=`) everywhere in `always @(posedge clk)` blocks.
- All ports and internal signals declared `signed` explicitly — Verilog does not propagate signedness automatically.
- `acc_out` is registered, so testbench checks the output one clock cycle after applying inputs.
- The `signed` keyword on `wire`/`reg` declarations is required; without it, multiplication and comparison treat values as unsigned.
- **Timing Closure**: Target 100MHz (10ns period) using `constraints.xdc`.
