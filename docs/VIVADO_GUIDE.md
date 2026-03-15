# Vivado Toolchain Guide

This guide details how to compile, simulate, and debug the MAC unit using Xilinx Vivado 2024.2.

## Environment Setup
The tools are located at `/home/aleem/Vivado/2024.2/bin`. Ensure this path is in your `PATH` or use the provided Makefile.

## Compilation Flow
1. **Parsing (`xvlog`)**: Parses Verilog/SystemVerilog sources.
2. **Elaboration (`xelab`)**: Generates a simulation snapshot.
3. **Simulation (`xsim`)**: Runs the snapshot.

## Command Reference
- Compile: `make compile` (runs `xvlog --sv`)
- Simulate: `make simulate` (runs `xelab` and `xsim`)
- Clean: `make clean`

## Waveform Debugging
To view waveforms:
1. Run `make simulate`.
2. Open the resulting `.wdb` file in Vivado GUI or use the `-tclbatch wave.tcl` flag with `xsim`.
