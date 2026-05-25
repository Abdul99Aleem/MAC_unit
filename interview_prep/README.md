# 4-Day Interview Mastery Plan: INT8 Systolic Array on Zynq

This roadmap will prepare you to defend your INT8 4x4 Systolic Array project in interviews with companies like AMD, Qualcomm, and Apple.

## The Goal
Master the hardware architecture, SoC integration (AXI4-Lite), ML quantization theory, and system-level trade-offs so you can confidently whiteboard and explain every design decision.

## Schedule Overview

- [ ] [Day 1: Hardware Foundation & DSP Architecture](./DAY_1_Hardware_Foundation.md)
  - *Focus:* Systolic arrays, DSP48E1 slices, Verilog fundamentals, Timing analysis.
  - *Company Alignment:* AMD (Xilinx), Intel, Hardware Design roles.

- [ ] [Day 2: AXI Protocol & SoC Integration](./DAY_2_AXI_Integration.md)
  - *Focus:* AXI4-Lite handshaking, PS-PL boundary, Register Maps, Bottleneck analysis.
  - *Company Alignment:* AMD (Xilinx), Qualcomm, SoC Architecture, Embedded Systems.

- [ ] [Day 3: AI/ML Quantization Theory](./DAY_3_Quantization_Theory.md)
  - *Focus:* INT8 math, PyTorch PTQ, scale/zero-point, BRAM initialization.
  - *Company Alignment:* Qualcomm (Hexagon DSP), Apple (ANE), Edge AI roles.

- [ ] [Day 4: System Thinking & Interview Defense](./DAY_4_System_Thinking.md)
  - *Focus:* End-to-end architecture, whiteboard pitching, future improvements, resume defense.
  - *Company Alignment:* System Architecture roles, Final Round / Hiring Manager interviews.

## Daily Structure
Each day is structured to build your mental model progressively:
- **Morning (2 hrs):** Deep concept study. Draw a 10-minute concept map.
- **Afternoon (2 hrs):** Hands-on review of your actual project code.
- **Evening (1 hr):** Practice questions and "no notes" self-testing.

## High-Level Resume Bullet
*Make sure you can defend every word of this:*
> "Designed INT8 4x4 systolic array on Zynq FPGA; achieved Xms PL vs Yms PS baseline, with weights loaded via AXI-lite from Python."

---
*Ready to begin? Start with [Day 1](./DAY_1_Hardware_Foundation.md).*