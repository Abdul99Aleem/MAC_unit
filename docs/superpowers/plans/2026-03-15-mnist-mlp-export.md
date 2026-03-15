# MNIST MLP Training & Weight Export Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Train a 2-layer MLP on MNIST and export its weights as INT8 hex files for Verilog simulation.

**Architecture:** 784 (Input) -> 64 (Hidden, ReLU) -> 10 (Output). Symmetric post-training quantization to INT8. Export in row-major hex format (2's complement).

**Tech Stack:** PyTorch, torchvision, numpy.

---

### Task 1: Environment Setup

**Files:**
- Create: `requirements.txt`

- [ ] **Step 1: Create requirements.txt**
```text
torch
torchvision
numpy
```

- [ ] **Step 2: Install dependencies**
Run: `pip install -r requirements.txt`

- [ ] **Step 3: Commit**
```bash
git add requirements.txt
git commit -m "chore: add python dependencies for mnist training"
```

---

### Task 2: Implement Training Script

**Files:**
- Create: `train_mnist.py`
- Output: `mnist_mlp.pt`

- [ ] **Step 1: Implement MLP architecture and training loop**
Create `train_mnist.py` with:
- `MNISTMLP` class (784 -> 64 -> 10).
- Data loading with `torchvision`.
- Adam optimizer, CrossEntropyLoss.
- Training loop (5 epochs).

- [ ] **Step 2: Implement symmetric quantization**
In `train_mnist.py`, after training:
- For each linear layer:
  - `scale = 127.0 / weight.abs().max()`
  - `q_weight = (weight * scale).round().clamp(-128, 127).to(torch.int8)`
- Save the state dict to `mnist_mlp.pt`.

- [ ] **Step 3: Run training**
Run: `python3 train_mnist.py`
Expected: Training completes, accuracy > 90% (printed), `mnist_mlp.pt` created.

- [ ] **Step 4: Commit**
```bash
git add train_mnist.py
git commit -m "feat: implement mnist training with int8 quantization"
```

---

### Task 3: Implement Weight Export Script

**Files:**
- Create: `export_weights.py`
- Output: `weights_layer1.mem`, `weights_layer2.mem`

- [ ] **Step 1: Implement hex export logic**
Create `export_weights.py` to:
- Load `mnist_mlp.pt`.
- Helper function: `to_hex(val)` -> `format(val & 0xFF, '02x')`.
- Extract `fc1.weight` (64, 784) and `fc2.weight` (10, 64).
- Write to `.mem` files in row-major order (one hex value per line).

- [ ] **Step 2: Run export**
Run: `python3 export_weights.py`
Expected: `weights_layer1.mem` (50,176 lines) and `weights_layer2.mem` (640 lines) created.

- [ ] **Step 3: Commit**
```bash
git add export_weights.py
git commit -m "feat: implement weight export to hex format"
```

---

### Task 4: Final Verification

**Files:**
- Check: `weights_layer1.mem`, `weights_layer2.mem`

- [ ] **Step 1: Verify file lengths**
Run: `wc -l weights_layer1.mem weights_layer2.mem`
Expected: 50176 and 640.

- [ ] **Step 2: Spot check hex values**
Run: `head -n 5 weights_layer1.mem`
Expected: 2-character hex strings (e.g., `0a`, `ff`, `00`).

- [ ] **Step 3: Commit**
```bash
git add weights_layer1.mem weights_layer2.mem
git commit -m "docs: export final mnist weights for hardware simulation"
```
