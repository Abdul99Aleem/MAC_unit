# Systolic Array 4x4 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a 4x4 systolic array of MAC units with internal skewing registers for simplified matrix multiplication.

**Architecture:** A 4x4 grid of processing elements (PEs) where each PE is a `mac_unit`. Internal shift registers delay row and column inputs to synchronize the computation wavefront. Data propagation between PEs is handled via top-level registers.

**Tech Stack:** Verilog, Vivado 2024.2.

---

## Chunk 1: RTL Implementation

### Task 1: Create systolic_array_4x4.v

**Files:**
- Create: `systolic_array_4x4.v`

- [ ] **Step 1: Define module and skewing registers**
Define the 4x4 input ports and the 1D-3D delay chains for rows and columns.

- [ ] **Step 2: Implement data propagation grid**
Define registers to hold the 'a' and 'b' values as they move horizontally and vertically through the array.

- [ ] **Step 3: Instantiate 16 mac_units**
Use nested generate loops to instantiate the 16 PEs and connect them to the propagation registers and skew buffers.

- [ ] **Step 4: Connect local accumulation feedback**
Wire each PE's `acc_out` back to its `acc_in` to enable local dot-product accumulation.

## Chunk 2: Verification & Docs

### Task 2: Update Makefile and Toolchain

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Add systolic array targets**
Update `SRCS` to include the new array and a testbench (to be created in Task 3).

### Task 3: Create Testbench

**Files:**
- Create: `systolic_array_tb.v`

- [ ] **Step 1: Implement matrix multiplication test case**
Feed two 4x4 matrices into the array (skewed by the module) and verify the 16 results against expected products.

### Task 4: Documentation Updates

**Files:**
- Modify: `docs/ARCHITECTURE.md`
- Modify: `README.md`

- [ ] **Step 1: Update Architecture doc**
Add the 4x4 grid diagram and explain the internal skewing logic.

- [ ] **Step 2: Update README**
Add the 4x4 array to the "Quick Start" and "Architecture" sections.
