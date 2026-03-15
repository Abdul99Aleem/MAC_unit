# Design Spec: MAC Unit Documentation & GitHub Readiness

**Date:** 2026-03-15
**Topic:** Documentation and repository preparation for a 4x4 Systolic Array 8-bit Signed MAC Unit.

## 1. Goal
Prepare the `MAC_unit` repository for GitHub by providing comprehensive, educational, and functional documentation that explains both the "how" (toolchain) and the "why" (architecture/math).

## 2. Architecture
The documentation will follow a modular approach (Approach 1):
- **`README.md`**: Entry point with high-level summary and quick-start guides.
- **`docs/VIVADO_GUIDE.md`**: Technical guide for the Vivado 2024.2 toolchain, compilation commands, and waveform debugging.
- **`docs/ARCHITECTURE.md`**: Deep dive into signed MAC mathematics, Verilog implementation details (signed keywords, registered outputs), and systolic array integration.

## 3. Component Details

### 3.1 README.md
- **Title**: 8-bit Signed MAC Unit
- **Visuals**: Mermaid.js diagram of the MAC data path.
- **Commands**: `make compile`, `make simulate`, `make clean`.
- **Navigation**: Links to `docs/VIVADO_GUIDE.md` and `docs/ARCHITECTURE.md`.

### 3.2 docs/VIVADO_GUIDE.md
- **Commands Explained**: Detailed breakdown of `xvlog`, `xelab`, and `xsim`.
- **Waveforms**: Instructions for `wave.tcl` usage and interpreting the resulting `.wdb` files.
- **Environment**: Path requirements for Vivado 2024.2.

### 3.3 docs/ARCHITECTURE.md
- **Math**: $acc_{out} = acc_{in} + (a \times b)$.
- **Implementation**: Why `signed` is used, the benefit of registered `acc_out` for timing, and DSP48 mapping.
- **Future Scope**: Scaling to a 4x4 Systolic Array.

## 4. Testing & Verification
- Verify all links between documents.
- Ensure all commands listed in the docs match the `Makefile` and `CLAUDE.md`.
- Verify the Mermaid diagrams render correctly.
