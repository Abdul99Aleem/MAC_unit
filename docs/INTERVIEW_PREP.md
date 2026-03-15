# Interview Preparation: Systolic Array Design

This document covers high-level design questions and trade-offs related to the 4x4 Systolic Array implementation, specifically tailored for VLSI/FPGA hardware engineering interviews.

## 1. Why a Systolic Array for Matrix Multiplication?
**Answer:** Matrix multiplication $C = A \times B$ has $O(N^3)$ operations but only $O(N^2)$ data. A systolic array allows us to reuse each data element $N$ times as it passes through the grid, reducing the memory bandwidth requirement from $O(N^3)$ to $O(N^2)$.

## 2. What is "Skewing" and why is it necessary?
**Answer:** In a 2D grid, data takes time to travel. $A_{0,0}$ reaches $PE_{0,0}$ at $T=0$, but $A_{1,0}$ (row 1) shouldn't meet $B_{0,0}$ until $B_{0,0}$ has finished its work for row 0.
- **Internal Skewing**: We delay Row $i$ by $i$ cycles and Col $j$ by $j$ cycles.
- **Benefit**: It simplifies the external controller. The user can feed rows and columns in a "natural" order, and the hardware handles the spatial-temporal alignment.

## 3. Stationary Output vs. Weight Stationary
**Answer:**
- **Stationary Output (Our Design)**: The accumulator ($C_{i,j}$) stays in the PE. Data ($A$ and $B$) flows through. Good for small matrices where reading out the whole grid at once is acceptable.
- **Weight Stationary**: Weights ($W$) are pre-loaded into PEs. Inputs ($X$) flow through. This is common in AI accelerators (like Google's TPU) because it minimizes movement of large weight matrices.

## 4. How does this design achieve Timing Closure?
**Answer:** Every horizontal and vertical "hop" between PEs is registered (`a_reg` and `b_reg` in our code). This means the **Critical Path** is always just the logic inside one single PE (1 multiplier + 1 adder), regardless of whether the array is 4x4 or 100x100. This is the definition of a scalable systolic architecture.

## 5. Signed vs. Unsigned Pitfalls
**Answer:** In Verilog, if one operand is unsigned, the entire expression becomes unsigned.
- **Our Fix**: We explicitly used the `signed` keyword on all ports, wires, and registers. We also used `8'sd0` (signed decimal) for literals to ensure 2's complement sign extension works correctly during multiplication.

## 6. Vivado/Xilinx Specifics
- **DSP48 Slices**: We designed the `mac_unit` to match the structure of a Xilinx DSP48 slice (Mult -> Add -> Reg). Vivado's synthesis engine will automatically "infer" these slices, leading to much higher performance and lower power than using general LUT logic.

## 7. AXI4-Lite vs. AXI4-Full for SoC Integration
**Answer:**
- **AXI4-Lite**: Simplified, low-area interface. No burst support. Best for control/status registers (CSRs) where we only write/read 32 bits at a time.
- **AXI4-Full**: Supports high-performance memory bursts. Best for high-bandwidth data transfers (e.g., streaming matrix data from DDR to FPGA).
- **Our Choice**: We used AXI4-Lite for simplicity and to provide a "Software API" like interface to the registers.

## 8. What is a "Memory-Mapped" Peripheral?
**Answer:** It's a hardware module whose internal registers are assigned to specific addresses in the CPU's memory space. The CPU can use standard load/store instructions (like `*ptr = value`) to control the hardware. This is the foundation of SoC (System-on-Chip) design.
