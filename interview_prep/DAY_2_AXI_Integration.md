# DAY 2 — AXI & SoC Integration

**Focus:** AXI4-Lite Protocol, PS-PL Boundary, Register Maps, Timing Diagrams
**Target Companies:** AMD (Xilinx), Qualcomm, SoC Architecture, Embedded Systems
**Goal:** Master the communication layer between the ARM processor and your custom hardware accelerator.

---

## MORNING (2 hrs): Deep Concept Study

### 10-Minute Concept Map (Draw by hand)
Sketch the following:
1.  **Zynq Architecture:** Draw the Processing System (PS - ARM Cortex) and Programmable Logic (PL - FPGA). Show the AXI Interconnect bridging them.
2.  **AXI4-Lite Handshake:** Draw the `AWVALID`/`AWREADY` (Address Write) and `WVALID`/`WREADY` (Data Write) timing diagram for a single register write.
3.  **Register Map:** Create a quick table showing Addresses `0x00`-`0x1C` (Inputs), `0x20`-`0x5C` (Results), and `0xA0` (Control).

### Core Concepts

#### What is AXI4-Lite? (Why not AXI4-Full or AXI-Stream?)
-   **AXI4-Lite:** A lightweight, memory-mapped protocol for simple, low-throughput control registers. One address = one data word. Perfect for setting up your systolic array inputs and reading final results.
-   **AXI4-Full:** Supports burst transfers (one address, multiple data words). Great for high-bandwidth DMA transfers, but overkill and too complex for simple control registers.
-   **AXI-Stream:** High-speed, unidirectional data flow with no addresses. Ideal for continuously streaming pixels or audio into an accelerator, but less flexible for a register-mapped matrix multiplier.

#### PS-PL Architecture on Zynq
-   **Processing System (PS):** The hard-silicon ARM Cortex-A9 processor. Runs Linux (or bare-metal), executes your Python (`inference_benchmark.py`), manages memory, and handles network/storage.
-   **Programmable Logic (PL):** The FPGA fabric where your `systolic_array_4x4.v` lives.
-   **The Bridge:** The PS acts as the AXI Master, initiating reads/writes. Your `top_level.v` is the AXI Slave, responding to those requests.

#### Register Map Design
-   **0x00 - 0x1C (Inputs):** Mapped to the Activation and Weight inputs of your array.
-   **0x20 - 0x5C (Results):** Mapped to the `acc_out` signals.
-   **0xA0 (Control):** The "Enable Bit" or "Start Strobe." Since your array is pipelined, writing a '1' here pulses the clock enable for the MAC units, pushing data one step through the pipeline.

#### AXI Handshake Protocol (Valid/Ready)
-   The fundamental rule of AXI: A transfer only occurs when both `VALID` (Master says data is good) and `READY` (Slave says I can take it) are high on the same rising clock edge.
-   *Master must not wait for `READY` to assert `VALID`.*

#### How Python/pynq/dev/mem Works
-   **Python -> C -> OS -> Hardware:** When Python writes to an array mapped via `/dev/mem` (or PYNQ's `MMIO`), the Linux kernel translates that virtual address to a physical address on the AXI bus. The ARM CPU executes a physical memory store instruction, which travels over the AXI interconnect to your PL register.

#### Critical Path Analysis (Bottlenecks)
-   **Where is the bottleneck?** In this design, the bottleneck is **not** the systolic array computation. It is the **AXI4-Lite bus**. Writing 16 inputs and reading 16 outputs sequentially over a 32-bit AXI-Lite bus takes many clock cycles, completely starving the systolic array of data. Real designs use DMA (Direct Memory Access) and AXI-Stream to feed data fast enough to keep the array busy.

---

## AFTERNOON (2 hrs): Hands-On Code Review

**Files to Reference:**
-   `top_level.v`
-   `inference_benchmark.py`

**Tasks:**
1.  Open `top_level.v`. Find the state machine or combinatorial logic that handles AXI Writes (`S_AXI_AWVALID`, `S_AXI_WVALID`). How do you generate the `S_AXI_WREADY` response?
2.  Find address `0xA0`. How is the enable pulse generated? Is it a single clock cycle pulse (self-clearing)?
3.  Open `inference_benchmark.py`. Trace how the weights from the PyTorch model are packed and written to the PL base address. How is the latency measured here vs. the pure PS numpy baseline?

---

## EVENING (1 hr): Practice Questions & Self-Test

**Self-Test:** Explain the AXI Valid/Ready handshake out loud. Draw it. Explain why you chose AXI-Lite instead of DMA for this V1 project.

### 5 Interview Questions (Qualcomm/SoC Focus)

1.  **"Draw the AXI write transaction timing diagram. What happens if the Master asserts VALID but the Slave keeps READY low for 5 cycles?"**
    *   *Answer:* The Master must hold VALID and the data stable for all 5 cycles. The transaction only completes on the rising edge where both are high. If the Slave stalls, the Master stalls.

2.  **"Why did you use AXI4-Lite for your systolic array? What is its main limitation?"**
    *   *Answer:* I used AXI4-Lite because it's simple to implement for control registers and sufficient for a proof-of-concept 4x4 array where I manually load weights and activations. Its main limitation is throughput—it only supports single beats (no bursts), making it impossible to keep the systolic array fed with data at 100MHz. A production design would use DMA and AXI-Stream.

3.  **"Explain your register map. How does the PS tell the PL to start computing?"**
    *   *Answer:* Addresses 0x00-0x1C hold inputs, 0x20-0x5C hold outputs. I mapped a specific control register at 0xA0. When the ARM CPU writes a '1' to 0xA0, it generates a 1-cycle enable strobe in the PL, which clocks the pipeline registers in the systolic array. I have to pulse this multiple times to push the wavefront through the array.

4.  **"In your `inference_benchmark.py`, you measured PL latency vs PS latency. Where is the majority of the time spent in the PL measurement?"**
    *   *Answer:* The majority of the time is spent on the AXI-Lite overhead—specifically, the Linux kernel context switches, `mmap` overhead, and sequential single-word AXI writes/reads. The actual 100MHz FPGA computation takes nanoseconds, but the software overhead takes microseconds/milliseconds.

5.  **"What is the difference between a virtual address in your Python script and the physical address on the AXI bus? How are they connected?"**
    *   *Answer:* Python operates in Linux virtual memory space. The physical AXI address (e.g., 0x43C0_0000) is a hardwired memory map in the Zynq architecture. I use `/dev/mem` (or PYNQ's MMIO) to tell the Linux kernel's Memory Management Unit (MMU) to map my Python script's virtual memory page directly to that physical AXI hardware address.