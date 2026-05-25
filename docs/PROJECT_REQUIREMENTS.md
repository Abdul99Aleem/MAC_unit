# Project Requirements Document (PRD)
## 8-bit Signed Systolic Array Accelerator for MNIST Inference

**Project Status**: ✅ COMPLETE  
**Last Updated**: 2026-04-13  
**Target Platform**: Xilinx Zynq-7000 (xc7z020clg400-1)

---

## 1. PROJECT OVERVIEW

### 1.1 Objective
Design and implement a hardware accelerator for matrix multiplication operations used in neural network inference, specifically targeting MNIST digit classification. The accelerator demonstrates the complete ML-to-hardware pipeline including quantization, RTL design, SoC integration, and verification.

### 1.2 Success Criteria
- ✅ Functional 4x4 systolic array with correct matrix multiplication
- ✅ AXI4-Lite integration for PS-PL communication
- ✅ INT8 quantization with numerical parity verification
- ✅ Timing closure at 100MHz target frequency
- ✅ Complete documentation for portfolio/interview use

---

## 2. FUNCTIONAL REQUIREMENTS

### 2.1 Core Hardware (MAC Unit)
- **FR-1.1**: 8-bit signed multiply-accumulate operation
- **FR-1.2**: 32-bit accumulator to prevent overflow
- **FR-1.3**: Synchronous active-low reset
- **FR-1.4**: Enable signal for cycle-accurate control
- **Status**: ✅ COMPLETE - Implemented in `mac_unit.v`

### 2.2 Systolic Array Architecture
- **FR-2.1**: 4x4 grid of MAC units (16 PEs total)
- **FR-2.2**: Stationary-output dataflow mapping
- **FR-2.3**: Internal data skewing for wavefront synchronization
- **FR-2.4**: Registered data propagation between PEs
- **Status**: ✅ COMPLETE - Implemented in `systolic_array_4x4.v`

### 2.3 SoC Integration
- **FR-3.1**: AXI4-Lite slave interface for memory-mapped access
- **FR-3.2**: Register map for inputs (0x00-0x1C), outputs (0x20-0x5C), control (0xA0)
- **FR-3.3**: Self-clearing enable strobe for precise control
- **FR-3.4**: READY/VALID handshake protocol compliance
- **Status**: ✅ COMPLETE - Implemented in `top_level.v`

### 2.4 ML Pipeline
- **FR-4.1**: PyTorch MLP training (784→64→10 architecture)
- **FR-4.2**: Symmetric INT8 quantization (post-training)
- **FR-4.3**: Weight export to .mem format for hardware
- **FR-4.4**: Numerical parity verification between HW and SW
- **Status**: ✅ COMPLETE - Implemented in `train_mnist.py`, `export_weights.py`, `inference_benchmark.py`

---

## 3. NON-FUNCTIONAL REQUIREMENTS

### 3.1 Performance
- **NFR-1.1**: Target clock frequency: 100MHz (10ns period)
- **NFR-1.2**: Timing closure with positive slack
- **Status**: ✅ ACHIEVED - WNS = 2.274ns (MET)

### 3.2 Resource Utilization
- **NFR-2.1**: Fit within Zynq-7000 resource budget
- **NFR-2.2**: Optimize for LUT/FF efficiency
- **Status**: ✅ ACHIEVED - 1709 LUTs (3.21%), 953 FFs (0.90%)

### 3.3 Verification
- **NFR-3.1**: Unit testbench for MAC unit
- **NFR-3.2**: Integration testbench for systolic array
- **NFR-3.3**: System-level testbench for AXI interface
- **NFR-3.4**: Python benchmark for numerical verification
- **Status**: ✅ COMPLETE - All testbenches pass

### 3.4 Documentation
- **NFR-4.1**: Architecture documentation
- **NFR-4.2**: Interview preparation materials
- **NFR-4.3**: Build/simulation instructions
- **NFR-4.4**: Code comments and inline documentation
- **Status**: ✅ COMPLETE - Comprehensive documentation provided

---

## 4. TECHNICAL SPECIFICATIONS

### 4.1 Data Types
- **Input/Weight**: 8-bit signed integer (INT8), range [-128, 127]
- **Accumulator**: 32-bit signed integer (INT32)
- **AXI Bus**: 32-bit address, 32-bit data

### 4.2 Timing
- **Clock Period**: 10ns (100MHz)
- **Pipeline Latency**: 7-12 cycles (skewing + propagation + MAC)
- **Throughput**: 16 MACs/cycle (when pipeline is full)

### 4.3 Memory Map
| Address Range | Function | Access |
|--------------|----------|--------|
| 0x00 - 0x0C | A_IN[0:3] (Row inputs) | Write |
| 0x10 - 0x1C | B_IN[0:3] (Col inputs) | Write |
| 0x20 - 0x5C | ACC_OUT[0:15] (Results) | Read |
| 0xA0 | CONTROL (Enable/Done) | Read/Write |

---

## 5. DESIGN DECISIONS & RATIONALE

### 5.1 Why 4x4 Array?
- **Rationale**: Balances demonstration value with manageable complexity. Large enough to show systolic principles, small enough for clear documentation and fast synthesis.
- **Alternative Considered**: 8x8 array (rejected due to increased complexity for educational project)

### 5.2 Why AXI4-Lite vs. AXI4-Full?
- **Rationale**: Simpler protocol, adequate for control/status registers. Lower logic footprint.
- **Trade-off**: Lower throughput, but acceptable for demonstration purposes.
- **Future Enhancement**: AXI-Stream + DMA for production use

### 5.3 Why Stationary-Output Mapping?
- **Rationale**: Simplifies result readout (all accumulators available simultaneously). Good for small matrices.
- **Alternative Considered**: Weight-stationary (better for large models, but requires complex weight loading)

### 5.4 Why INT8 Symmetric Quantization?
- **Rationale**: Hardware simplicity (no zero-point subtraction), adequate accuracy for MNIST.
- **Trade-off**: Slightly less optimal for asymmetric distributions (e.g., post-ReLU activations)

### 5.5 DSP Slice Utilization
- **Design Intent**: Target DSP48 slices using `(* use_dsp = "yes" *)` attribute
- **Actual Result**: Vivado synthesized to LUTs (0 DSPs used)
- **Explanation**: At 8x8 bit width, Vivado's cost model determined LUT implementation was more efficient
- **Impact**: Still meets timing (WNS = 2.274ns), demonstrates correct RTL coding practices
- **Note**: Larger arrays or wider bit-widths would trigger DSP inference

---

## 6. VERIFICATION RESULTS

### 6.1 Functional Verification
- ✅ MAC unit testbench: All test cases pass
- ✅ Systolic array testbench: 4x4 matrix multiplication verified
- ✅ AXI testbench: Protocol compliance verified
- ✅ Numerical parity: INT8 predictions match FP32 baseline

### 6.2 Synthesis Results
- **LUTs**: 1709 / 53200 (3.21%)
- **Registers**: 953 / 106400 (0.90%)
- **DSPs**: 0 / 220 (0.00%) - LUT implementation chosen by synthesizer
- **Timing**: WNS = 2.274ns, WHS = 0.083ns (ALL CONSTRAINTS MET)

### 6.3 Benchmark Results
- **PL Latency (Simulated)**: ~0.9ms per inference
- **PS Baseline (NumPy)**: ~0.05ms per inference
- **Note**: PL latency is software simulation overhead, not representative of actual FPGA performance
- **Numerical Accuracy**: 100% prediction match on test samples

---

## 7. DELIVERABLES

### 7.1 Source Code
- ✅ `mac_unit.v` - Core processing element
- ✅ `systolic_array_4x4.v` - 4x4 grid instantiation
- ✅ `top_level.v` - AXI4-Lite wrapper
- ✅ `*_tb.v` - Testbenches (3 files)
- ✅ `train_mnist.py` - ML training and quantization
- ✅ `export_weights.py` - Weight extraction
- ✅ `inference_benchmark.py` - Numerical verification

### 7.2 Build Infrastructure
- ✅ `Makefile` - Simulation automation
- ✅ `create_project.tcl` - Vivado automation
- ✅ `constraints.xdc` - Timing constraints
- ✅ `requirements.txt` - Python dependencies

### 7.3 Documentation
- ✅ `README.md` - Quick start guide
- ✅ `MASTER_NOTES.md` - Comprehensive technical reference
- ✅ `docs/ARCHITECTURE.md` - Design details
- ✅ `docs/VIVADO_GUIDE.md` - Toolchain instructions
- ✅ `docs/INTERVIEW_PREP.md` - Interview Q&A
- ✅ `interview_prep/` - 4-day study plan

### 7.4 Generated Artifacts
- ✅ `utilization.txt` - Synthesis resource report
- ✅ `timing.txt` - Timing analysis report
- ✅ `weights_layer1.mem` - Quantized weights (50,176 values)
- ✅ `weights_layer2.mem` - Quantized weights (640 values)

---

## 8. KNOWN LIMITATIONS & FUTURE WORK

### 8.1 Current Limitations
1. **AXI4-Lite Bandwidth**: Sequential register access limits throughput
2. **Fixed Array Size**: 4x4 grid is hardcoded, not parameterizable
3. **No On-Chip Weight Storage**: Weights must be loaded via AXI each time
4. **Software Simulation Only**: No actual FPGA deployment (Zynq board not available)

### 8.2 Recommended Enhancements
1. **DMA + AXI-Stream**: High-bandwidth data streaming
2. **Parameterizable Array Size**: Generic N×N implementation
3. **BRAM Weight Buffers**: On-chip weight storage
4. **Hardware Requantization**: INT32→INT8 scaling in hardware
5. **Double Buffering**: Hide AXI latency with ping-pong buffers
6. **FPGA Deployment**: Actual Zynq board testing with PYNQ

---

## 9. PROJECT TIMELINE

- **Week 1**: MAC unit design and verification
- **Week 2**: Systolic array implementation
- **Week 3**: AXI4-Lite integration and synthesis
- **Week 4**: ML pipeline and numerical verification
- **Week 5**: Documentation and interview preparation

**Total Effort**: ~5 weeks (part-time)

---

## 10. CONCLUSION

This project successfully demonstrates the complete hardware-software co-design flow for ML acceleration:
- ✅ All functional requirements met
- ✅ All non-functional requirements met
- ✅ Comprehensive verification completed
- ✅ Portfolio-ready documentation delivered

The project serves as a strong portfolio piece for VLSI/FPGA/AI hardware engineering roles, demonstrating competency in RTL design, SoC integration, ML quantization, and system-level thinking.
