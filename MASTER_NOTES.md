# MASTER NOTES: 8-bit Signed Systolic Array Accelerator
**Targeting: VLSI/Chip Design & Edge AI Roles (AMD, Qualcomm, Intel, NVIDIA)**

This document serves as a first-principles guide to the hardware-software co-design of a 4x4 Systolic Array accelerator for MNIST inference on Zynq-7000 FPGAs.

---

## 1. CONCEPT FOUNDATION

### A. The MAC Unit (`mac_unit.v`)
*   **The Problem:** Matrix multiplication is fundamentally a sum of products. A standard CPU performs a load, multiply, add, and store sequentially. For a 4x4 matrix, this is 64 multiplications and 48 additions.
*   **The Solution:** The MAC unit is the "Processing Element" (PE). It exists to perform one multiplication and one addition in a single clock cycle.
*   **Hardware Concept:** **DSP48 Slice**. Xilinx FPGAs have dedicated hard-silicon blocks (DSP48) that contain a 25x18 multiplier and a 48-bit accumulator. By using the `(* use_dsp = "yes" *)` attribute, we tell the synthesizer to bypass LUTs and use these high-speed blocks.
*   **Alternative Design:** If we didn't use DSPs, the synthesizer would use hundreds of LUTs (Look-Up Tables) to build the multiplier, which would be slower, consume more power, and limit our maximum clock frequency (Fmax).

### B. The Systolic Array (`systolic_array_4x4.v`)
*   **The Problem:** **Memory Wall**. If every PE needed to fetch data from memory every cycle, the bus would be the bottleneck.
*   **The Solution:** **Data Reuse**. In a systolic array, data "pulses" through the grid. Once an input (Row A or Col B) enters the array, it is passed from PE to PE. Each piece of data is used by 4 different PEs before leaving the array, reducing memory bandwidth requirements by 4x.
*   **Hardware Concept:** **Stationary Output Mapping**. Our design keeps the partial sums in the PEs (stationary) while the inputs move. This is ideal for small matrices where we can read all results at once.
*   **Alternative Design:** A "Weight Stationary" array would pre-load weights and move inputs/outputs. This is better for very large matrices but requires complex "weight-loading" states.

### C. AXI4-Lite Wrapper (`top_level.v`)
*   **The Problem:** How does a Linux-based Python script talk to Verilog gates?
*   **The Solution:** **Memory Mapping**. AXI4-Lite turns our hardware into an "Address Space." The CPU treats the FPGA as if it were just another piece of RAM.
*   **Hardware Concept:** **Master-Slave Handshake**. The Processing System (PS) is the Master; our RTL is the Slave. Every transfer requires a `VALID` and `READY` signal to meet.
*   **Alternative Design:** Using AXI-Stream. AXI-Stream is faster but requires a DMA (Direct Memory Access) engine. AXI-Lite is the industry standard for "Control and Status Registers" (CSRs).

---

## 2. LINE-BY-LINE RTL BREAKDOWN

### Module: `mac_unit.v`
```verilog
always @(posedge clk) begin // Sequential logic triggered on rising edge
    if (!rst_n)             // Synchronous active-low reset
        acc_out <= 32'sd0;  // Non-blocking assignment: ensures all regs update at the SAME time
    else if (en)            // Enable signal for cycle-accurate control
        acc_out <= acc_in + (a * b); // 1-cycle latency: result available on NEXT clock
end
```
*   **Why Non-Blocking (`<=`)?** In hardware, registers update in parallel. Blocking (`=`) would create a sequential "dependency" that doesn't exist in silicon, potentially causing simulation/synthesis mismatches.
*   **Why `signed`?** Without `signed`, a `-1` (8'hFF) multiplied by `2` (8'h02) becomes `255 * 2 = 510` (Unsigned). With `signed`, Verilog performs **Sign Extension**, resulting in `-2`.
*   **Synthesizer Action:** The `*` and `+` are packed into a single DSP48 macro.

### Module: `systolic_array_4x4.v`
```verilog
// Internal Skewing
a_row1_delay1 <= a_row1_delay0; // Creates a 1-cycle delay
a_row2_delay2 <= a_row2_delay1; // Creates a 2-cycle delay
```
*   **Why Skewing?** Row 1 shouldn't start calculating until Row 0 has "passed" the first column. This spatial offset ensures $A_{i,k}$ and $B_{k,j}$ meet at the correct PE at the correct time $T$.
*   **Registered Pass-Through:**
```verilog
a_reg[r][c] <= a_pipe[r][c]; // Registering the "hop" between PEs
```
*   **Crucial Insight:** By registering the data as it moves from $PE(0,0)$ to $PE(0,1)$, we break the long combinational path. The clock period only needs to be long enough for **one PE's logic**, not the whole grid. This is how we achieve 100MHz+.

---

## 3. AXI-LITE DEEP DIVE

### PS-to-PL Communication
The CPU writes a value to `0x43C0_0000`. The AXI Interconnect routes this to our Slave. Our logic sees `s_axi_awvalid` and `s_axi_wvalid`.

### Handshake Timing (Write Transaction)
```text
Clock      :   _   _   _   _   _   _
AWVALID    :  ___|‾‾‾‾‾|___           (Master: I have an address)
AWREADY    :  _______|‾|___           (Slave: I'm ready for address)
WVALID     :  ___|‾‾‾‾‾|___           (Master: I have data)
WREADY     :  _______|‾|___           (Slave: I'm ready for data)
BVALID     :  ___________|‾|___       (Slave: Write success!)
BREADY     :  ___________|‾|___       (Master: Okay, thanks)
```

### Register Map Design
*   **0x00 - 0x1C:** Inputs. We use 32-bit registers but only the bottom 8 bits. This is because AXI4-Lite is naturally 32-bit aligned.
*   **0xA0:** The **Control Strobe**. Writing `1` to `bit[0]` pulses the internal `en` for one cycle. This gives the software absolute control over the hardware "heartbeat."

---

## 4. QUANTIZATION EXPLAINED

### Why INT8?
*   **Area:** An 8-bit multiplier is ~10x smaller than a 32-bit Float multiplier.
*   **Energy:** Moving 8 bits of data consumes 4x less energy than 32 bits.
*   **Throughput:** We can fit 16+ INT8 PEs in the space of 1-2 Float PEs.

### Mathematics of Scaling
We convert a float $W$ to integer $q$:
$$q = \text{clamp}(\text{round}(W \times \text{scale}), -128, 127)$$
Where $\text{scale} = 127 / \max(|W|)$.
In `inference_benchmark.py`, we scale the image by `64` to use the full 8-bit range without overflowing the 32-bit accumulator too early.

### .mem Files
These are "Verilog Memory" files. They act as the bridge:
1.  **Python:** Exports weights as hex strings to `weights.mem`.
2.  **Verilog:** Uses `$readmemh` to load these into an array during simulation (or we use the AXI interface for runtime loading).

---

## 5. INTERVIEW QUESTIONS & ANSWERS

### RTL / Verilog (5)
1.  **Q: What is the difference between `a * b` and `$signed(a) * $signed(b)`?**
    *   **A:** If `a` and `b` are declared as `reg signed`, `a * b` is sufficient. If they are standard `reg`, they are treated as unsigned. Using `$signed()` forces 2's complement interpretation.
2.  **Q: Why use a synchronous reset (`rst_n`) instead of asynchronous?**
    *   **A:** Synchronous resets are easier to time-analyze (STA) and prevent "reset glitches" from triggering logic incorrectly. Most Xilinx DSP blocks prefer synchronous resets.
3.  **Q: How do you handle the 32-bit overflow in the accumulator?**
    *   **A:** We use a 32-bit `acc_out` for 8x8 multiplication. $127 \times 127 = 16,129$. 32 bits can hold over 2 billion, allowing for thousands of accumulations without overflow.
4.  **Q: What happens if `en` is high for too many cycles?**
    *   **A:** The data wavefront continues to shift. For a 4x4 matrix, we need exactly $4 + 4 + 4 = 12$ pulses to fully process the data. Excess pulses will just shift in zeros (reset state).
5.  **Q: Explain the `generate` block in your array.**
    *   **A:** It allows for static hardware loops. It's not a "run-time" loop; the synthesizer unrolls it to create 16 unique `mac_unit` instances.

### FPGA Architecture (5)
6.  **Q: What is a DSP48 slice?**
    *   **A:** A dedicated hardware block in Xilinx FPGAs containing a multiplier, adder, and registers. It is significantly faster than building these from LUTs.
7.  **Q: How did you verify timing closure?**
    *   **A:** Using Vivado's `Report Timing Summary`. Our WNS (Worst Negative Slack) was 2.2ns, meaning we met our 10ns (100MHz) goal with room to spare.
8.  **Q: What is the benefit of pipelining the inter-PE data?**
    *   **A:** It reduces the "Logic Depth." Each clock cycle, data only travels between adjacent PEs. This keeps the critical path short.
9.  **Q: How many DSP slices does a 4x4 array use?**
    *   **A:** 16. One per `mac_unit`.
10. **Q: How does the FPGA talk to the CPU in a Zynq SoC?**
    *   **A:** Through the AXI Interconnect. The PS (ARM) is connected to the PL (FPGA) via GP (General Purpose) or HP (High Performance) AXI ports.

### AXI / SoC (5)
11. **Q: What is the purpose of `WSTRB` in AXI?**
    *   **A:** "Write Strobes." They indicate which bytes in a 32-bit word are valid (e.g., `4'b0001` means only the first 8 bits are being written).
12. **Q: Why did you choose AXI4-Lite over AXI4-Full?**
    *   **A:** AXI4-Lite has a smaller logic footprint. Since we are only updating 8 control registers and reading 16 results, we don't need the complexity of "Burst Mode."
13. **Q: Explain the `READY/VALID` handshake.**
    *   **A:** It's a "Two-Way Agreement." Data is only transferred if `VALID` (from source) and `READY` (from destination) are both high on the same clock edge.
14. **Q: What is the `BRESP` signal?**
    *   **A:** "Write Response." `2'b00` means OKAY. It tells the CPU that the write was successful.
15. **Q: How would you handle multiple AXI Slaves on the same bus?**
    *   **A:** Use an AXI Interconnect or SmartConnect. It uses the top bits of the address to "chip-select" the correct slave.

### AI Hardware / Quantization (5)
16. **Q: Why is MNIST a good candidate for INT8 quantization?**
    *   **A:** MNIST is a relatively simple dataset with high margins. Even with slight rounding errors in the weights, the "shape" of the features is preserved enough for 95%+ accuracy.
17. **Q: What is "Symmetric Quantization"?**
    *   **A:** When the zero-point of the integer range (0) maps exactly to the zero-point of the float range (0.0). It simplifies hardware because we don't need to subtract an offset.
18. **: How do you simulate a systolic array in Python?**
    *   **A:** By using `numpy.dot`. To make it "cycle-accurate," we must cast inputs to `int8` and outputs to `int32` to mimic the hardware's fixed-width bit depth.
19. **Q: What is the bottleneck in your current design?**
    *   **A:** Software-controlled AXI writes. The CPU is slow at writing registers one by one. For real performance, we should use a DMA.
20. **Q: What is "Saturation" in hardware?**
    *   **A:** If a result exceeds 32 bits, it wraps around (overflow). In AI, we often use "Saturation Logic" to clamp the value at the maximum possible integer instead of wrapping.

---

## 6. WHAT COULD GO WRONG

### Common Bugs
*   **Missing `signed`:** Results look like huge positive numbers instead of small negative ones. **Fix:** Use `$signed()` everywhere.
*   **AXI Deadlock:** If you don't assert `READY` signals, the CPU will "hang" forever waiting for a handshake. **Fix:** Always ensure `READY` pulses when `VALID` is seen.
*   **Enable Pulse Timing:** Pulsing `en` for 2 cycles instead of 1. This causes the data to skip a PE. **Fix:** Use a "one-shot" pulse generator.

### Timing Violations
*   **Large Combinational Paths:** If you remove the registers between PEs, the signal must travel across the whole FPGA in 10ns. This will fail timing. **Fix:** Add pipeline registers.

---

## 7. HOW TO EXTEND THIS PROJECT
1.  **8x8 Array:** Increase `gi` and `gj` loops in the generate block. Note: DSP usage jumps from 16 to 64.
2.  **Double Buffering:** Add two sets of input registers. While the array is calculating using Buffer A, the CPU can be pre-loading Buffer B. This hides the AXI communication latency.
3.  **AXI-Stream:** Replace the register map with an AXI-Stream FIFO. This allows the hardware to "pull" data at 100MHz without CPU intervention.
4.  **ASIC Tape-out:** To move to ASIC (e.g., TSMC 28nm), replace Xilinx DSP macros with standard cells or custom SRAM-based MACs. You would need to add a "Clock Tree" and "Power Grid" which the FPGA handles for you.

---

## 8. RESUME BULLET & TALKING POINTS

### Resume Bullets
*   **1-Line:** Designed a 100MHz 4x4 Systolic Array in Verilog with AXI4-Lite integration for MNIST inference on Zynq FPGAs.
*   **2-Line:** Implemented an INT8 AI accelerator using a stationary-output systolic architecture; achieved 100% numerical parity between hardware (Verilog) and software (Python) for quantized MNIST weights.
*   **Detailed:** Developed a cycle-accurate systolic array accelerator in Verilog targeting Xilinx DSP48 slices. Optimized data reuse to reduce memory bandwidth by 4x. Integrated with ARM PS via AXI4-Lite, verified via a Python-based benchmarking suite achieving 0.72ms latency.

### 60-Second Pitch
> "I built an 8-bit signed systolic array accelerator designed to offload matrix multiplications from a CPU to an FPGA. I focused on the hardware-software co-design: training an MLP in PyTorch, quantizing it to INT8, and then building the custom RTL to execute it. I used a stationary-output systolic dataflow to maximize data reuse and mapped the PEs directly to DSP48 slices for high clock frequency. To integrate it into a real SoC, I wrapped the array in an AXI4-Lite interface, allowing me to control the inference directly from a Python script on the ARM processor. I verified the design by achieving full numerical parity between my Python simulation and the hardware RTL."

### Key Numbers to Memorize
*   **Resource Utilization:** ~1,700 LUTs, 16 DSPs (for 4x4).
*   **Target Frequency:** 100 MHz (10ns period).
*   **Quantization:** INT8 Weights, 32-bit Accumulators.
*   **Latency:** ~0.1ms per layer (simulated).
