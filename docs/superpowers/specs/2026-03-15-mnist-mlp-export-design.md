# MNIST MLP Training & Weight Export Design

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this design.

**Goal:** Train a 2-layer MLP on MNIST and export its weights as INT8 hex files for Verilog simulation.

**Architecture:**
- **Model**: 784 (Input) -> 64 (Hidden, ReLU) -> 10 (Output).
- **Quantization**: Symmetric post-training quantization to INT8 (mapping weights to range [-128, 127]).
- **Export**: Row-major order, 1 hex byte per line, compatible with `$readmemh`.

## Components

### 1. `train_mnist.py`
- **Purpose**: Train the MLP, apply post-training quantization, and save the model.
- **Library**: PyTorch, torchvision.
- **Architecture**: 784 (Input) -> 64 (Hidden, ReLU) -> 10 (Output).
- **Hyperparameters**:
  - Optimizer: Adam
  - Loss: CrossEntropyLoss
  - Epochs: Max 5
- **Quantization**:
  - After training, calculate symmetric scale factor $S = 127 / \max(|W|)$ for each linear layer.
  - Apply quantization: $W_{q} = \text{round}(W \times S)$.
  - Clip to $[-128, 127]$.
- **Output**: `mnist_mlp.pt` (Quantized model state containing INT8 weights).

### 2. `export_weights.py`
- **Purpose**: Extract quantized weights and format for hardware.
- **Process**:
  1. Load `mnist_mlp.pt`.
  2. For each linear layer:
     - Get weight tensor (already quantized to INT8 range).
     - Convert each signed integer to its 8-bit hex representation (2's complement).
     - Python logic: `format(int(val) & 0xFF, '02x')`.
  3. Write to `.mem` files in row-major order (one value per line).
- **Output**:
  - `weights_layer1.mem` (64x784 values)
  - `weights_layer2.mem` (10x64 values)
  - Prints matrix shapes and value ranges (min/max) for verification.

### 3. `requirements.txt`
- `torch`
- `torchvision`
- `numpy`

## Success Criteria
- [ ] `mnist_mlp.pt` is generated and contains the expected state dict.
- [ ] `weights_layer1.mem` contains exactly 50,176 hex entries.
- [ ] `weights_layer2.mem` contains exactly 640 hex entries.
- [ ] Hex values are valid 2-character strings (00-ff).
- [ ] No bias terms are included in the export.
