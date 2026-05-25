# DAY 1 — Hardware Foundation

**Focus:** Core Systolic Array Concepts, DSP48 Slices, Verilog Fundamentals
**Target Companies:** AMD (Xilinx), Intel, Custom Silicon teams
**Goal:** Master the raw math-to-hardware mapping and explain why your RTL synthesizes effectively.

---

## MORNING (2 hrs): Deep Concept Study

### 10-Minute Concept Map (Draw by hand)
Sketch the following:
1.  **MAC Unit:** `acc_out <= acc_in + (a * b)` showing the registers (pipeline stages).
2.  **4x4 Grid:** Show horizontal flow (activations) and vertical flow (weights).
3.  **Data Skewing:** Draw a timing diagram or staggered input matrix showing why data must be delayed (skewed) entering the array to meet at the correct MAC unit at the right clock cycle.

### Core Concepts

#### Why a Systolic Array? (vs. a simple MAC loop)
-   **Problem:** A simple MAC loop reads from memory, multiplies, and writes back. Memory bandwidth becomes the bottleneck (Von Neumann bottleneck).
-   **Solution:** A systolic array reads data once and pumps it through an array of processing elements (PEs). It maximizes data reuse (O(N) memory accesses for O(N^2) computation) and achieves massive parallelism.

#### How Data Flows (Skewing, Pipelining, Wavefront)
-   **Pipelining:** Every MAC unit has registered outputs. It takes 1 clock cycle to move data from PE(i,j) to PE(i,j+1).
-   **Skewing:** To ensure Activation(0,0) meets Weight(0,0) at PE(0,0) at T=0, and Activation(0,1) meets Weight(0,1) at PE(0,1) at T=1, inputs must be staggered (skewed) in time before entering the array. This creates a diagonal "wavefront" of computation.

#### Why 8-bit Signed (INT8)? (Tradeoffs)
-   **FP32:** High dynamic range and precision, but requires complex floating-point units (huge area, high power). Unnecessary for many neural networks.
-   **INT16:** Better precision than INT8, but uses 4x the multiplier resources (in area/power) compared to INT8.
-   **INT8 Signed:** The industry standard for edge inference. Neural networks are highly resilient to quantization noise. Using *signed* INT8 allows for negative weights and activations without complex offset math in hardware.

#### DSP48E1 Slices on Zynq
-   **What it is:** A dedicated, hard-silicon block on Xilinx FPGAs optimized for Multiply-Accumulate operations (typically 25x18 multiplier + 48-bit accumulator).
-   **Inference:** `mac_unit.v` uses `(* use_dsp = "yes" *)` to tell Vivado to map `acc_out <= acc_in + (a * b)` directly to a DSP48 slice, saving LUTs and drastically improving Fmax (maximum clock frequency).

#### Blocking vs Non-Blocking Assignments
-   **Blocking (`=`):** Executes sequentially. Bad for sequential logic; infers combinatorial logic.
-   **Non-Blocking (`<=`):** Evaluates all right-hand sides, then updates all left-hand sides simultaneously at the end of the time step. **Mandatory** for modeling flip-flops and pipelining (like your MAC registers).

#### Vivado Synthesis & Timing Reports
-   **Timing Closure:** The goal is positive Slack. Slack = Required Time - Arrival Time.
-   **What it tells you:** If you fail timing (negative slack), the report shows the critical path (the longest combinatorial delay between two flip-flops). In a systolic array, this usually means you need more pipeline registers or better DSP packing.

---

## AFTERNOON (2 hrs): Hands-On Code Review

**Files to Reference:**
-   `mac_unit.v`
-   `systolic_array_4x4.v`

**Tasks:**
1.  Open `mac_unit.v`. Point to the exact line that infers the DSP48 slice. Explain why the `signed` keyword is critical here (otherwise Vivado does unsigned math, breaking ML results).
2.  Open `systolic_array_4x4.v`. Trace the path of `activation_in[0]` and `weight_in[0]` to `pe_0_0`. Trace how `pe_0_0`'s output feeds `pe_0_1` and `pe_1_0`.
3.  Look at your skewing logic (if implemented in RTL or assumed in Python). How many clock cycles does it take for the first valid result to emerge from the array? (Latency calculation).

---

## EVENING (1 hr): Practice Questions & Self-Test

**Self-Test:** Close your laptop. Can you draw a 2x2 systolic array and trace the data flow for 3 clock cycles?

### 5 Interview Questions (AMD/Hardware Focus)

1.  **"Explain the difference between blocking and non-blocking assignments. What happens if you use blocking assignments in your MAC unit?"**
    *   *Answer:* Non-blocking (`<=`) models parallel flip-flop updates. Blocking (`=`) models sequential evaluation. If I used `=` in a clocked `always` block for my MAC pipeline, Vivado might infer a long combinatorial chain instead of a true pipeline register, causing timing failures and incorrect cycle-by-cycle behavior.

2.  **"Why did you choose INT8 over FP32 for this design? How did it impact your hardware utilization?"**
    *   *Answer:* FP32 provides unnecessary precision for MNIST and requires massive LUT/FF resources for floating-point adders/multipliers. INT8 maps perfectly to the native DSP48 slices on the Zynq, allowing me to pack more MAC units into a smaller area and run at a higher Fmax with lower power, which is critical for edge AI.

3.  **"What is a DSP48 slice? How do you ensure Vivado uses it instead of LUTs for your multiplier?"**
    *   *Answer:* It's a hard-silicon block optimized for math (25x18 mult + 48-bit add). I write DSP-optimized RTL (`acc_out <= acc_in + a * b` in an `always @(posedge clk)` block) and use the synthesis attribute `(* use_dsp = "yes" *)`. However, the synthesizer makes cost-based decisions—in my design, Vivado chose LUT implementation for 8x8 multipliers as it was more efficient at that scale. The design still meets timing at 100MHz.

4.  **"What is the theoretical maximum throughput (in MACs/cycle) of your 4x4 array? What is the initial latency?"**
    *   *Answer:* Max throughput is 16 MACs/cycle once the pipeline is full. The initial latency is approximately 7-12 clock cycles (accounting for skewing, propagation, and MAC pipeline stages) before the first result emerges.

5.  **"You look at your Vivado timing report and see a Negative Setup Slack of -2.5ns. What does this mean, and how do you fix it?"**
    *   *Answer:* It means the combinatorial delay between two registers is 2.5ns too long for the target clock period. To fix it, I would look at the critical path in the report. Solutions include adding pipeline registers (retiming) to break up the logic, ensuring multipliers are mapped to DSP slices, or reducing the target clock frequency.