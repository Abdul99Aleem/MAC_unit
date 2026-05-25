# DAY 3 — AI/ML + Quantization Theory

**Focus:** INT8 Quantization Math, PyTorch PTQ, ML on Edge Devices
**Target Companies:** Qualcomm (Hexagon DSP), Apple (ANE), Edge AI roles
**Goal:** Master the translation of floating-point neural networks to fixed-point hardware and explain the accuracy/performance tradeoffs.

---

## MORNING (2 hrs): Deep Concept Study

### 10-Minute Concept Map (Draw by hand)
Sketch the following:
1.  **Quantization Equation:** $r = S(q - Z)$. Where $r$ is the real (FP32) value, $S$ is the scale factor (FP32), $q$ is the quantized value (INT8), and $Z$ is the zero-point (INT8).
2.  **PyTorch PTQ Flow:** Show the steps: Train FP32 Model $\rightarrow$ Fuse Layers (Conv+BN+ReLU) $\rightarrow$ Insert Observers (Calibration) $\rightarrow$ Convert to INT8.
3.  **Data Formats:** Draw the memory layout of your MNIST input (28x28 = 784 bytes) and how it maps to your $784 \rightarrow 64 \rightarrow 10$ MLP architecture.

### Core Concepts

#### Why Quantize to INT8?
-   **Memory Bandwidth:** INT8 reduces the model size by 4x compared to FP32, drastically cutting memory access energy (the biggest power draw in ML inference).
-   **Compute Density:** INT8 multipliers are significantly smaller and consume less power than FP32 multipliers. You can pack more MACs into the same silicon area (higher GOPS/W).
-   **Cache Efficiency:** Smaller models fit entirely in on-chip SRAM, avoiding slow/expensive off-chip DRAM access.

#### Post-Training Quantization (PTQ) vs Quantization-Aware Training (QAT)
-   **PTQ:** Train in FP32, then calculate Scale ($S$) and Zero-Point ($Z$) by running calibration data (a subset of the training set) through the model to observe the min/max activation ranges. Fast, but can lose accuracy if weight distributions are wide or have outliers.
-   **QAT:** Simulate quantization effects during training (using "fake quantization" nodes). The model learns to adapt to the quantization noise. Takes longer but usually recovers the accuracy lost in PTQ.

#### Scale Factors ($S$) and Zero Points ($Z$)
-   **Symmetric Quantization:** $Z = 0$. The range is $[-127, 127]$ (for signed INT8). Simpler hardware implementation because you don't have to subtract $Z$ during the MAC operation: $\sum (q_a \cdot q_w) = \frac{1}{S_a S_w} \sum r_a r_w$.
-   **Asymmetric Quantization:** Uses a non-zero $Z$. The range is typically $[0, 255]$ (unsigned UINT8). Better for skewed distributions (like activations after a ReLU, which are all positive), but requires extra hardware logic to handle the cross-terms: $(q_a - Z_a)(q_w - Z_w)$. Your hardware likely uses symmetric signed INT8 to simplify the MAC.

#### The Math of INT8 Inference
If $r = S(q - Z)$ and we use symmetric quantization ($Z=0$), then $r = S \cdot q$.
A matrix multiplication $C = A \cdot B$ in FP32 becomes:
$S_c \cdot q_c = (S_a \cdot q_a) \cdot (S_w \cdot q_w)$
$q_c = \left( \frac{S_a \cdot S_w}{S_c} \right) \cdot (q_a \cdot q_w)$

The hardware computes the INT32 accumulator: $\sum (q_a \cdot q_w)$.
The software (or a dedicated scaling unit in hardware) multiplies the result by the FP32 multiplier $M = \frac{S_a S_w}{S_c}$ and rounds back to INT8.

#### BRAM Initialization (`$readmemh`)
-   FPGA Block RAM (BRAM) can be initialized with data at bitstream load time using `$readmemh` (hex) or `$readmemb` (binary) in Verilog.
-   Your Python script extracts the INT8 weights from the PyTorch model and formats them into a `.mem` file, which Vivado reads during synthesis/simulation.

#### Edge AI Context
-   **Your Project:** A custom hardware accelerator built from scratch. Highly optimized but inflexible.
-   **TensorFlow Lite / ONNX Runtime:** Software frameworks that map ML graphs to CPU/GPU/DSP ISAs (like ARM NEON or Qualcomm Hexagon). They rely on the underlying hardware's vector instructions.

---

## AFTERNOON (2 hrs): Hands-On Code Review

**Files to Reference:**
-   `train_mnist.py`
-   `export_weights.py`
-   `inference_benchmark.py`

**Tasks:**
1.  Open `train_mnist.py`. Trace the PyTorch quantization API calls (`torch.quantization.prepare`, `torch.quantization.convert`). Where is the calibration dataset used?
2.  Open `export_weights.py`. Look at how you extract the weights from the quantized layers (e.g., `model.fc1.weight().int_repr()`). How are these formatted into the `.mem` file? Are they signed or unsigned?
3.  Open `inference_benchmark.py`. Compare the software inference loop (NumPy/PyTorch) to the hardware interaction loop (AXI writes/reads). How do you handle the scaling factor ($M$) in your benchmark?

---

## EVENING (1 hr): Practice Questions & Self-Test

**Self-Test:** Write down the quantization equation $r = S(q - Z)$ and derive the MAC operation showing where the INT32 accumulation happens.

### 5 Interview Questions (ML/Quantization Focus)

1.  **"What is the equation linking a floating-point value to its quantized integer representation? Explain the roles of Scale and Zero-Point."**
    *   *Answer:* $r = S(q - Z)$. $r$ is the real FP32 value, $S$ is the FP32 scale factor defining the step size, $q$ is the quantized integer, and $Z$ is the integer zero-point that maps to the real value 0.0. $Z$ handles asymmetric distributions.

2.  **"Why did you use Post-Training Quantization (PTQ) instead of Quantization-Aware Training (QAT)? What accuracy drop did you observe?"**
    *   *Answer:* I used PTQ because it's significantly faster to implement and sufficient for a relatively simple dataset like MNIST on an MLP. The accuracy drop was minimal (e.g., 98% to 97.5%) because MLPs are robust to quantization noise. If the drop was unacceptable, I would have used QAT to simulate the INT8 noise during the forward pass of training.

3.  **"In your hardware, you perform an INT8 $\times$ INT8 multiplication. The result requires more than 8 bits. How many bits do you need for the accumulator, and how do you prevent overflow?"**
    *   *Answer:* An INT8 $\times$ INT8 multiplication requires 16 bits. Accumulating these products requires more bits depending on the length of the dot product ($N$). For a dot product of length $N$, you need $16 + \log_2(N)$ bits to guarantee no overflow. My DSP48 slice has a 48-bit accumulator, which is virtually impossible to overflow in this context.

4.  **"How did you extract the weights from PyTorch and get them into your FPGA?"**
    *   *Answer:* After running `torch.quantization.convert`, I accessed the quantized weight tensors using `.int_repr().numpy()`. I wrote a Python script to format these integer arrays into a hexadecimal `.mem` file. Vivado uses `$readmemh` to initialize the BRAM or LUT RAM with these values during synthesis.

5.  **"When your hardware finishes the MAC operation, it holds an INT32 (or larger) value. How does that value get converted back to INT8 for the next layer?"**
    *   *Answer:* The INT32 accumulator result must be multiplied by a "requantization scale factor" $M = \frac{S_{in} S_w}{S_{out}}$ and then rounded and clamped to the $[-128, 127]$ range. In my current simple AXI-Lite design, this scaling is likely done in software on the ARM PS after reading the result. A production design would implement this scaling and clamping in hardware at the output of the array.