# MAC Unit Architecture

## Mathematical Theory
The Multiply-Accumulate (MAC) unit performs:
$$acc_{out} = acc_{in} + (a \times b)$$

## Implementation Details
- **Signed Arithmetic**: Uses the `signed` keyword for all ports. **Warning**: Missing `signed` results in incorrect unsigned math.
- **Pipelining**: `acc_out` is registered on the rising edge of `clk`.
- **Reset**: Synchronous active-low reset (`rst_n`).

## Systolic Array 4x4
The `systolic_array_4x4` module tiles 16 MAC units in a 4x4 grid.

### Space-Time Mapping
To perform matrix multiplication $C = A \times B$, the array uses **stationary-output** mapping:
1. **Internal Skewing**: Inputs are delayed by $i$ cycles for row $i$ and $j$ cycles for column $j$ to ensure operands meet at the correct PE at the correct time.
2. **Data Propagation**: Values of $A$ move horizontally and $B$ move vertically through the grid, registered at each hop.
3. **Local Accumulation**: Each PE accumulates its partial product locally by feeding `acc_out` back to `acc_in`.

### Grid Topology
```mermaid
graph TD
    subgraph Row_Skew
        R0[a0]
        R1[a1 + D]
        R2[a2 + 2D]
        R3[a3 + 3D]
    end
    subgraph Col_Skew
        C0[b0]
        C1[b1 + D]
        C2[b2 + 2D]
        C3[b3 + 3D]
    end
    R0 --> PE00((PE 0,0))
    R1 --> PE10((PE 1,0))
    C0 --> PE00
    C1 --> PE01((PE 0,1))
    PE00 -- a --> PE01
    PE00 -- b --> PE10
    %% ... rest of grid ...
```

## AXI4-Lite Integration
The `top_level` module wraps the systolic array in an AXI4-Lite slave interface, enabling memory-mapped access to inputs, control registers, and results.

### Register Map
| Offset | Name      | Type | Description                       |
|--------|-----------|------|-----------------------------------|
| 0x00   | A_IN[0-3] | RW   | 8-bit row inputs (4 registers)    |
| 0x10   | B_IN[0-3] | RW   | 8-bit column inputs (4 registers) |
| 0x20   | ACC[0-15] | RO   | 32-bit PE results (16 registers)  |
| 0xA0   | CONTROL   | RW   | Bit 0: Enable, Bit 1: Done (RO)   |

### AXI Interface
The wrapper implements the standard 5-channel AXI4-Lite handshake logic (Write Address, Write Data, Write Response, Read Address, Read Data). It acts as a bridge between the processor's memory bus and the systolic array's streaming ports.

## Resource Utilization
This design is optimized for Xilinx Zynq FPGAs. Each `mac_unit` infers a single **DSP48** slice, totaling 16 DSPs for the 4x4 array.
