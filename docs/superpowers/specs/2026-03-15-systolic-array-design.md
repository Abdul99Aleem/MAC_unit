# Systolic Array 4x4 Design Specification

## Overview
A 4x4 systolic array of Multiply-Accumulate (MAC) units designed for matrix multiplication acceleration. The design uses internal skewing registers to simplify the external interface.

## Architecture
- **PE (Processing Element)**: Each PE is an instance of `mac_unit`.
- **Grid Structure**: 4 rows by 4 columns of PEs.
- **Skew Buffers**: Internal shift registers to delay row and column inputs, ensuring data wavefront synchronization.
- **Top-Level Propagation**: Because the `mac_unit` is used without modification, all horizontal (row) and vertical (column) data propagation registers are implemented in the `systolic_array_4x4` module.
- **Feedback Accumulation**: Each PE connects its own `acc_out` to `acc_in`, enabling it to accumulate local products over multiple cycles.

## Data Flow (Systolic Timing)
- Row $i$ is delayed by $i$ clock cycles.
- Column $j$ is delayed by $j$ clock cycles.
- PE $(i, j)$ receives $A_{i}$ at cycle $i+j$ and $B_{j}$ at cycle $i+j$.

## Module Interface
- `clk`, `rst_n`: Global clock and active-low synchronous reset.
- `a_in [31:0]`: 4 concatenated 8-bit signed row inputs.
- `b_in [31:0]`: 4 concatenated 8-bit signed column inputs.
- `acc_out [511:0]`: 16 concatenated 32-bit signed accumulator outputs.

## Educational Insights (VLSI Focus)
- **Space-Time Mapping**: The design demonstrates how a 2D matrix multiplication algorithm is mapped into a physical 2D grid over time.
- **Resource Reuse**: In a real systolic array, `acc_in` of a PE would be connected to `acc_out` of the previous PE to perform larger sums. For this 4x4 unit, each PE accumulates its own local product.
- **Timing Closure**: By registering every signal at every hop, the design ensures short critical paths, regardless of the array size.
