# GOD LEVEL MASTERCLASS: INT8 Systolic Array on Zynq

**Target Audience:** 3rd-Year ECE Undergrad
**Goal:** Take you from zero context to complete mastery of the end-to-end ML-to-Hardware pipeline. We will cover PyTorch, Quantization, Verilog, AXI4-Lite, Vivado Tcl scripting, and bare-metal Python inference.

This document traces the exact chronological journey of building this project from Hour 1 to Hour 6.

---

## The Big Picture: What did we actually build?

Standard CPUs (like the Intel in your laptop) are "Von Neumann" machines. They fetch an instruction, fetch data from memory, compute, and write back to memory. For Machine Learning—which is basically billions of multiplications—fetching from memory every single time is a massive bottleneck.

**The Solution:** A Custom Hardware Accelerator (Systolic Array).
Instead of fetching data over and over, we load the weights into the FPGA once. Then, we pump the inputs (activations) through a grid of multipliers. The data flows like blood through a heart (systole)—hence "systolic array."

To do this, we need a complete System-on-Chip (SoC) design:
1. **The Brain (PS):** An ARM processor running Linux and Python.
2. **The Muscle (PL):** The FPGA fabric running our custom Verilog.
3. **The Spinal Cord (AXI):** The bus that connects the Brain to the Muscle.

Here is how we built it, hour by hour.

---

## Hour 1: The ML & Math (Python/PyTorch)

*Before we build hardware, we need something for the hardware to do.*

### 1. Training the Model
We used PyTorch to train a simple Multi-Layer Perceptron (MLP) on the MNIST dataset (handwritten digits).
- **Input:** 28x28 pixel image = 784 numbers.
- **Hidden Layer:** 64 neurons.
- **Output:** 10 neurons (digits 0-9).
- **Math:** $Y = W \cdot X + B$. Just giant matrix multiplications.

### 2. Why INT8 Quantization?
PyTorch trains using 32-bit Floating Point (FP32). FP32 requires huge hardware multipliers (bad for FPGAs). So, we **quantize** the model to 8-bit Integers (INT8).
- FP32 takes 4 bytes. INT8 takes 1 byte. We just shrank our model by 4x and made the hardware 10x smaller.
- **The Math:** $Real\_Value = Scale \times (Quantized\_Value - Zero\_Point)$.
- We used **Symmetric Quantization** ($Zero\_Point = 0$). So, $Real\_Value = Scale \times INT8\_Value$.

### 3. Extracting the Weights (`export_weights.py`)
Once quantized, the weights are just arrays of numbers between -128 and +127. We wrote a Python script to pull these numbers out of PyTorch and save them into a `.mem` file (a simple hex text file). This file will later be baked into the FPGA's memory.

---

## Hour 2: The Core Hardware (Verilog MAC)

*Now we build the atomic unit of our muscle.*

### 1. The MAC Unit (`mac_unit.v`)
A Multiply-Accumulate (MAC) unit does exactly what it says: `Accumulator = Accumulator + (A * B)`.
- `A` is our activation (pixel/feature).
- `B` is our weight.

```verilog
always @(posedge clk) begin
    if (!reset_n) acc_out <= 0;
    else acc_out <= acc_in + (a * b);
end
```

### 2. The Secrets of the MAC
- **`signed` keyword:** In Verilog, if you don't explicitly say `signed wire [7:0] a`, Verilog assumes it's an unsigned number (0 to 255). We are using signed INT8 (-128 to +127). Forgetting `signed` breaks the math entirely.
- **Non-blocking assignments (`<=`):** This is crucial. `<= ` infers a Flip-Flop (a register). This creates a **pipeline stage**. It means the MAC takes exactly 1 clock cycle to produce an output.
- **DSP48 Slices:** Xilinx FPGAs have dedicated hard-silicon blocks for math called DSP48s. By writing our Verilog cleanly, Vivado automatically maps our MAC to a DSP48 slice, rather than building a slow multiplier out of thousands of basic logic gates (LUTs).

---

## Hour 3: The Grid (Verilog Systolic Array)

*Connecting 16 MACs together into a 4x4 matrix engine.*

### 1. The Architecture (`systolic_array_4x4.v`)
We instantiate 16 `mac_unit` modules in a 4x4 grid.
- Activations flow from Left to Right.
- Weights (or partial sums) flow from Top to Bottom.

### 2. The Data Skewing (The hardest concept)
You **cannot** feed all the data into the array at once.
Imagine data moving through the grid.
- At Clock 0: `Activation_0` meets `Weight_0` at the top-left MAC `PE(0,0)`.
- At Clock 1: The output of `PE(0,0)` moves down to `PE(1,0)`. To do the next piece of math, `Activation_1` must arrive at `PE(1,0)` at **Clock 1**.
- Therefore, we must delay (skew) `Activation_1` by 1 clock cycle before it enters the array. `Activation_2` is delayed by 2 cycles, etc. This creates a diagonal "wavefront" of data marching through the grid.

---

## Hour 4: The Bridge (AXI4-Lite & SoC Integration)

*How does the ARM CPU talk to the FPGA? This is where ECE students get lost. Pay attention.*

### 1. The PS and the PL
The Zynq chip has a hard ARM CPU (Processing System or **PS**) and an FPGA fabric (Programmable Logic or **PL**). They are physically distinct but sit on the same silicon die.

### 2. Memory-Mapped I/O
How does a Python script running on the ARM CPU flip a wire on the FPGA? **Memory Mapping**.
The ARM CPU thinks it's just writing to a memory address (e.g., `0x4000_0000`). But physically, that address doesn't point to RAM; it points to wires connected to the AXI bus bridging to the FPGA.

### 3. What is AXI4-Lite?
It's an ARM protocol for chips to talk to each other. "Lite" means it's simple: one address, one piece of data.
It relies on a **Handshake**:
- The Master (ARM CPU) puts an address and data on the bus and sets `VALID = 1` (saying "My data is ready").
- The Slave (Our FPGA) looks at the bus. When it's ready, it sets `READY = 1`.
- When both `VALID == 1` and `READY == 1` on a rising clock edge, the data transfers.

### 4. The Top Level Wrapper (`top_level.v`)
We wrote a massive state machine that speaks AXI-Lite.
- If the CPU writes to Addresses `0x00 - 0x1C`, we route that data to the input wires of our Systolic Array.
- If the CPU reads from Addresses `0x20 - 0x5C`, we send the `acc_out` wires back to the CPU.
- **The Magic "Go" Button (0xA0):** We mapped Address `0xA0` to an "Enable" wire. When the CPU writes a `1` here, we pulse the clock enable on our systolic array, advancing the pipeline by one cycle.

---

## Hour 5: The Build System (Tcl & Make)

*Clicking buttons in the Vivado GUI is for hobbyists. Scripting is for engineers.*

### 1. Why `create_project.tcl`?
Vivado is notorious for creating bloated project directories. If you change a setting in the GUI, it's hidden deep in an XML file.
We wrote a Tcl (Tool Command Language) script that:
1. Creates a blank project.
2. Imports our Verilog files.
3. Sets the target FPGA chip part number.
4. Runs Synthesis (converting Verilog to gates) and Implementation (placing those gates on the physical chip).

### 2. The Makefile
We wrapped the Tcl script in a Makefile. Now, typing `make compile` or `make synthesize` does everything automatically. It's reproducible, trackable in Git, and professional.

---

## Hour 6: The Software Stack (Python Inference)

*Closing the loop. Running the ML model on our custom silicon.*

### 1. `inference_benchmark.py`
We boot Linux on the ARM CPU. We write a Python script to test our hardware.

### 2. `/dev/mem` (The Linux Hack)
Linux usually blocks Python from accessing physical hardware addresses for security. By opening the special Linux file `/dev/mem` using the `mmap` library, we bypass the OS protections. We map our Python variables directly to the physical AXI base address (`0x4000_0000`).

### 3. The Execution Loop
1. **Load Weights:** Python writes the INT8 weights to the AXI addresses.
2. **Load Activations:** Python writes the MNIST image pixels to the AXI addresses.
3. **Pulse the Enable:** Python writes a `1` to `0xA0` multiple times to push the wavefront through the array.
4. **Read Results:** Python reads the final INT32 accumulators from `0x20-0x5C`.
5. **Requantize:** Python multiplies the INT32 result by the FP32 Scale Factor to get the final prediction.

### 4. The Benchmark
We ran the exact same inference using pure Python/NumPy on the ARM CPU (PS). Then we ran it using our FPGA (PL). The PL was significantly faster (latency measured in milliseconds/microseconds).

---

## Summary of Your "Superpowers" for the Interview

If you understand this document, you know:
1. **Algorithm:** How ML is just matrix multiplication.
2. **Hardware/Software Co-Design:** Why we use INT8 (math) to save space (silicon).
3. **Digital Design:** How to infer DSP blocks and create pipelined data paths using non-blocking Verilog.
4. **Computer Architecture:** How CPUs and FPGAs communicate over an AXI bus via memory-mapped I/O.
5. **DevOps:** How to automate EDA tools using Make and Tcl.

*You didn't just write code; you built a full-stack, cross-domain computing system.*