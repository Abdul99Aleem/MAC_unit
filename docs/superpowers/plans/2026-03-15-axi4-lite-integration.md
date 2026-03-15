# AXI4-Lite Integration & Vivado Automation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wrap the 4x4 systolic array in an AXI4-Lite slave interface for SoC integration and provide a TCL script for Vivado project automation.

**Architecture:**
- `top_level.v`: Wraps `systolic_array_4x4` with an AXI4-Lite slave.
- AXI registers provide access to `a_in`, `b_in`, `acc_out` (PE results), and control/status signals.
- `create_project.tcl`: Automates project setup, synthesis, and reporting for `xc7z020clg400-1`.

**Tech Stack:** Verilog, AXI4-Lite Protocol, Vivado TCL, Zynq-7000.

---

## Chunk 1: AXI4-Lite Top Level Wrapper

### Task 1: Implement `top_level.v` skeleton and AXI interface logic

**Files:**
- Create: `/home/aleem/Desktop/MAC_unit/top_level.v`

- [ ] **Step 1: Define module ports and AXI-Lite register infrastructure**
- [ ] **Step 2: Implement AXI Write logic (AW and W handshakes)**
- [ ] **Step 3: Implement AXI Read logic (AR and R handshakes)**
- [ ] **Step 4: Instantiate `systolic_array_4x4` and connect to internal registers**
- [ ] **Step 5: Implement Control/Status logic (Start/Done bits)**

### Task 2: Verify `top_level.v` with a basic AXI testbench

**Files:**
- Create: `/home/aleem/Desktop/MAC_unit/top_level_tb.v`

- [ ] **Step 1: Create AXI-Lite master model in testbench**
- [ ] **Step 2: Test writing to A-input registers (0x00-0x0C)**
- [ ] **Step 3: Test writing to B-input registers (0x10-0x1C)**
- [ ] **Step 4: Trigger array and read back results (0x20-0x5C)**
- [ ] **Step 5: Run simulation and verify protocol compliance**

## Chunk 2: Vivado Automation

### Task 3: Create `create_project.tcl`

**Files:**
- Create: `/home/aleem/Desktop/MAC_unit/create_project.tcl`

- [ ] **Step 1: Define project paths and target device (`xc7z020clg400-1`)**
- [ ] **Step 2: Add all source files to the project**
- [ ] **Step 3: Configure synthesis settings for DSP48 inference**
- [ ] **Step 4: Run synthesis and implementation**
- [ ] **Step 5: Export utilization and timing reports**

### Task 4: Verify Vivado Build

- [ ] **Step 1: Run `vivado -mode batch -source create_project.tcl`**
- [ ] **Step 2: Inspect `utilization.txt` and `timing.txt`**
- [ ] **Step 3: Verify no CRITICAL WARNINGS in log**

## Chunk 3: Documentation Updates

### Task 5: Update Documentation

**Files:**
- Modify: `/home/aleem/Desktop/MAC_unit/docs/ARCHITECTURE.md`
- Modify: `/home/aleem/Desktop/MAC_unit/docs/INTERVIEW_PREP.md`
- Modify: `/home/aleem/Desktop/MAC_unit/README.md`

- [ ] **Step 1: Document AXI4-Lite Register Map in `ARCHITECTURE.md`**
- [ ] **Step 2: Add AXI and SoC integration concepts to `INTERVIEW_PREP.md`**
- [ ] **Step 3: Update `README.md` with new file structure and usage instructions**
