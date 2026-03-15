# Vivado Toolchain Guide

This guide details how to compile, simulate, and debug the MAC unit using Xilinx Vivado 2024.2.

## Environment Setup
The tools are located at `/home/aleem/Vivado/2024.2/bin`. Ensure this path is in your `PATH` or use the provided Makefile.

## Compilation Flow
1. **Parsing (`xvlog`)**: Parses Verilog/SystemVerilog sources.
2. **Elaboration (`xelab`)**: Generates a simulation snapshot.
3. **Simulation (`xsim`)**: Runs the snapshot.

## Command Reference
- **Systolic Array (Default)**: `make simulate` runs the 4x4 matrix multiplication test.
- **Single MAC Unit**: `make simulate_mac` runs the unit test for a single processing element.
- **Clean**: `make clean` removes all simulation artifacts.

## Waveform Debugging
To view waveforms:
1. Run `make simulate`.
2. Open the resulting `.wdb` file (e.g., `systolic_array_4x4_tb_sim.wdb`) in Vivado GUI.
3. In the GUI, you can trace the data wavefront as it moves through `a_pipe` and `b_pipe`.

## Interview Tips: Simulation Verification
- **Functional Coverage**: The `systolic_array_4x4_tb` verifies that all 16 PEs correctly accumulate the dot product of two 4x4 matrices.
- **Timing Analysis**: In the simulation log, notice the time offset. Results appear after several clock cycles due to the combined delay of skewing (up to 3 cycles), propagation (up to 3 cycles), and the MAC pipeline (1 cycle).
