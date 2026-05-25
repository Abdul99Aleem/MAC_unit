# DAY 4 — System Thinking & Interview Defense

**Focus:** End-to-End Architecture, Whiteboard Pitch, Deflection Strategies
**Target Companies:** System Architecture Roles, Final Round / Hiring Manager Interviews
**Goal:** Synthesize your hardware, SoC, and ML knowledge into a cohesive story. Be able to pitch the project in 2 minutes, draw the full system architecture from memory, and defend your design choices against senior engineers.

---

## MORNING (2 hrs): Deep Concept Study

### 10-Minute Concept Map (Draw by hand)
Sketch the full system architecture (The "Whiteboard Diagram"):
1.  **Software Layer (PS/ARM):** Python Script $\rightarrow$ PyTorch Model $\rightarrow$ Quantization $\rightarrow$ Memory Map (`/dev/mem`).
2.  **Bus Interface:** AXI4-Lite Interconnect (32-bit Address, 32-bit Data).
3.  **Hardware Layer (PL/FPGA):** Top Level Wrapper $\rightarrow$ Registers (0x00, 0x20, 0xA0) $\rightarrow$ 4x4 Systolic Array $\rightarrow$ 16x MAC Units (DSP48).

### Core Concepts

#### The 2-Minute Elevator Pitch
*Format:* Problem $\rightarrow$ Solution $\rightarrow$ Results
*Draft:* "I built an end-to-end INT8 machine learning accelerator on a Zynq FPGA. The problem with standard CPUs is the memory bottleneck when calculating large matrix multiplications. My solution was a custom 4x4 systolic array written in Verilog that maps computation directly to the FPGA's DSP48 slices, maximizing data reuse. I trained and quantized an MNIST model in PyTorch down to INT8, wrote a custom Python script to load the weights over an AXI4-Lite bus, and benchmarked the inference latency. The hardware execution took X ns compared to Y ms on the ARM processor, demonstrating the massive parallel compute advantage of custom silicon."

#### System Bottlenecks & Future Improvements
*Interviewers love asking: "If you had 3 more months, what would you add?"*
1.  **DMA & AXI-Stream:** The current AXI-Lite bus limits throughput to 1 word per transaction. A DMA controller streaming data via AXI-Stream would keep the array fed at 100MHz.
2.  **Scale Up (Bigger Array):** Increase from 4x4 to 16x16 or 32x32 to handle modern convolution layers or transformer attention heads.
3.  **Hardware Requantization:** Currently, the INT32 accumulation is likely scaled and clamped back to INT8 in software. Moving this scaling logic to hardware at the edge of the array would reduce bus traffic.
4.  **Data Types:** Support for FP16 or Bfloat16 for tasks where INT8 quantization loses too much accuracy.
5.  **SRAM/BRAM Buffers:** Add local on-chip memory (Weight FIFO, Activation FIFO) to decouple the array from the slow AXI bus.

#### Connecting to Real Chips
-   **Google TPU (v1):** The original TPU was a massive 256x256 8-bit systolic array. Your design is a miniature version of this architecture.
-   **Apple Neural Engine (ANE):** Optimized for low-power mobile inference (heavy focus on INT8/FP16 MAC arrays).
-   **AMD Versal AI Core:** Uses "AI Engines" (VLIW vector processors) highly optimized for ML workloads.
-   **Qualcomm Hexagon DSP:** Focuses on HVX (Hexagon Vector eXtensions) for running quantized models at the edge.

#### Deflection Strategies (What if you don't know?)
*Never say "I don't know" and stop.*
*   *Strategy 1: Pivot to what you know.* "I haven't implemented AXI-Stream directly, but based on my experience with AXI-Lite, I know the key difference is dropping the address phase for burst throughput..."
*   *Strategy 2: Reason aloud.* "I'm not exactly sure how PyTorch handles asymmetric zero-points internally, but mathematically, it would require subtracting the zero-point before every multiplication in hardware, which I would implement by adding a pre-adder before the DSP slice."
*   *Strategy 3: Ask a clarifying question.* "Are you asking if the MAC unit overflows on a 16-bit boundary, or if the global accumulator overflows?"

---

## AFTERNOON (2 hrs): Hands-On Code Review

**Files to Reference:**
-   *All files* (Mental Walkthrough)

**Tasks:**
1.  **The Code Walk:** Open `top_level.v`. Assume the ARM processor just wrote `0x1` to address `0xA0` (Enable). Trace that signal through the top level, into the `systolic_array_4x4.v`, and into a `mac_unit.v`. Trace the resulting output back out to address `0x20`.
2.  **Resume Defense:** Look at your resume bullet: *"Designed INT8 4x4 systolic array on Zynq FPGA; achieved Xms PL vs Yms PS baseline, with weights loaded via AXI-lite from Python."*
    *   What does "Zynq" mean? (ARM + FPGA SoC).
    *   What is the exact X and Y? (Find the numbers in your benchmark script output).
    *   How did you measure the baseline? (NumPy/PyTorch CPU inference time).
    *   How are the weights loaded? (Memory-mapped IO via Python).

---

## EVENING (1 hr): Practice Questions & Self-Test

**Self-Test:** Stand up. Use a whiteboard (or a blank piece of paper) and draw the entire system diagram while explaining it out loud in exactly 2 minutes.

### 10 Hardest Interview Questions (Full System Focus)

1.  **"Walk me through the lifecycle of a single activation matrix multiplying against a weight matrix, from PyTorch to the FPGA output."**
    *   *Answer:* The model is trained and quantized to INT8 in PyTorch. The weights are exported to a `.mem` file and loaded into the PL via Python `mmap` over AXI-Lite. Activations are sent over AXI-Lite. The ARM CPU pulses the enable register (`0xA0`). The systolic array clocks the skewed activations and weights through the MACs. The results appear at `0x20-0x5C`. The Python script reads these addresses over AXI-Lite, applies the requantization scale factor, and calculates the final INT8 prediction.

2.  **"Your AXI-Lite interface takes multiple clock cycles per read/write. Your systolic array runs at 100MHz. How severely is your hardware starved for data?"**
    *   *Answer:* Extremely starved. AXI-Lite takes ~3-5 cycles minimum per 32-bit transfer, plus massive software overhead from Linux context switching in Python. The array finishes a MAC in 1 cycle, but waits hundreds of cycles for the next input. This is why AXI-Stream and DMA are critical next steps.

3.  **"How does your 4x4 array handle a matrix multiplication that is larger than 4x4 (e.g., 64x64)?"**
    *   *Answer:* A 4x4 array requires the software to "tile" the 64x64 matrix into 4x4 blocks. The CPU must orchestrate loading a 4x4 block, running the computation, storing the partial sum, and moving to the next block. This tiling logic adds significant software overhead.

4.  **"If you wanted to increase the clock frequency (Fmax) of your design from 100MHz to 250MHz, what steps would you take?"**
    *   *Answer:* I would look at the Vivado timing report to find the critical path. Common fixes: Ensure all MACs use DSP48 slices (`(* use_dsp="yes" *)`). Add pipeline registers between the AXI interface and the array. Add pipeline registers internally within the systolic array routing. Ensure block RAMs (if added later) use output registers.

5.  **"Explain the trade-offs between implementing this in an FPGA versus an ASIC."**
    *   *Answer:* FPGA is reconfigurable, faster time-to-market, and allows me to change the precision (e.g., INT4 to FP8) by just changing the bitstream. ASIC (like a TPU) has vastly higher NRE (non-recurring engineering) costs, takes years to tape out, but provides orders of magnitude better performance, area, and power efficiency for high-volume production.

6.  **"Why didn't you just use an off-the-shelf GPU for this inference?"**
    *   *Answer:* GPUs are excellent for batch inference (high throughput) but consume hundreds of watts. A Zynq FPGA allows for custom data paths with ultra-low latency (batch size 1) at very low power (a few watts), which is required for embedded edge AI applications like smart cameras or drones.

7.  **"How did you verify the functional correctness of your Verilog module before putting it on the FPGA?"**
    *   *Answer:* I wrote a `top_level_tb.v` testbench. I generated known-good input vectors (activations and weights) and expected output vectors using a Python script. The testbench applied the inputs via simulated AXI-Lite transactions and automatically compared the `acc_out` results against the expected Python output.

8.  **"What happens if you multiply two INT8 values (range -128 to 127) and the result overflows your accumulator?"**
    *   *Answer:* -128 * -128 = 16,384, requiring 15 bits. Accumulating 4 of these requires 17 bits. If I used an 8-bit or 16-bit accumulator, it would wrap around (modulo arithmetic), completely corrupting the neural network output. My DSP48 uses a 48-bit accumulator, so overflow is impossible for a 4x4 array.

9.  **"You used `signed` types in Verilog. How does 2's complement math impact the hardware size compared to unsigned math?"**
    *   *Answer:* Signed multipliers require sign extension and slightly more complex logic to handle the cross-products of the MSB (sign bit) compared to unsigned multipliers. However, because we map directly to DSP48 slices (which natively support 2's complement), the hardware size difference on the FPGA is effectively zero.

10. **"Pitch this project to me as if I am the Hiring Manager for the Apple Neural Engine team."**
    *   *Answer:* "I understand that ANE focuses heavily on maximizing MAC density at low power for INT8/FP16 mobile workloads. I built a custom INT8 systolic array on a Zynq SoC that implements those exact principles. I quantized a PyTorch model, mapped the data flow to DSP slices to maximize Fmax, and integrated it with an ARM processor over an AXI bus. While it's a proof-of-concept, it demonstrates my ability to take a model from high-level Python down to cycle-accurate RTL, which is exactly the skill set needed to optimize ANE architecture."