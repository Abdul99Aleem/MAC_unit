import numpy as np
import torch
from torchvision import datasets, transforms
import time
import os

def load_mem_file(file_path, shape):
    """Loads signed 8-bit hex values from a .mem file into a NumPy array."""
    with open(file_path, 'r') as f:
        hex_values = [line.strip() for line in f if line.strip()]

    # Convert hex to signed 8-bit integers
    ints = []
    for h in hex_values:
        val = int(h, 16)
        if val >= 128:
            val -= 256
        ints.append(val)

    return np.array(ints, dtype=np.int8).reshape(shape)

def run_benchmark():
    print("--- MNIST Hardware-Software Inference Benchmark ---\n")

    # 1. Load Weights from .mem files
    # Shapes: FC1 (64, 784), FC2 (10, 64)
    w1_pl = load_mem_file('weights_layer1.mem', (64, 784))
    w2_pl = load_mem_file('weights_layer2.mem', (10, 64))

    w1_ps = w1_pl.astype(np.float32)
    w2_ps = w2_pl.astype(np.float32)

    # 2. Load MNIST Test Data
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    test_set = datasets.MNIST('./data', train=False, download=True, transform=transform)
    test_loader = torch.utils.data.DataLoader(test_set, batch_size=10, shuffle=True)
    images, labels = next(iter(test_loader))

    # Convert first image to numpy for detailed analysis
    img = images[0].view(784).numpy()
    label = labels[0].item()

    # --- PL Inference Simulation (Integer) ---
    # In a real system, inputs are quantized to 8-bit.
    # We'll scale the normalized input to [-128, 127].
    img_q = (img * 64).clip(-128, 127).astype(np.int8)

    t0 = time.perf_counter()
    # Layer 1: Matrix Multiply + ReLU (simulated as max(0, x))
    # We use np.dot but ensure we cast to int32 to match hardware accumulators
    z1_pl = np.dot(w1_pl.astype(np.int32), img_q.astype(np.int32))
    a1_pl = np.maximum(0, z1_pl)

    # In systolic array, we usually requantize or stay in higher precision
    # For this benchmark, we'll keep it as int32 to match acc_out
    z2_pl = np.dot(w2_pl.astype(np.int32), a1_pl)
    pred_pl = np.argmax(z2_pl)
    t1 = time.perf_counter()
    pl_latency = (t1 - t0) * 1000

    # --- PS Inference Baseline (Float32) ---
    t0 = time.perf_counter()
    z1_ps = np.dot(w1_ps, img)
    a1_ps = np.maximum(0, z1_ps)
    z2_ps = np.dot(w2_ps, a1_ps)
    pred_ps = np.argmax(z2_ps)
    t1 = time.perf_counter()
    ps_latency = (t1 - t0) * 1000

    # 3. Print Results for Single Sample
    print(f"Sample Image Label: {label}")
    print(f"PL Prediction (INT8):    {pred_pl}")
    print(f"PS Prediction (Float32): {pred_ps}")
    print(f"Match: {'YES' if pred_pl == pred_ps else 'NO'}")
    print("-" * 40)
    print(f"PL Latency: {pl_latency:.4f} ms")
    print(f"PS Latency: {ps_latency:.4f} ms")
    print(f"Speedup Ratio (PS/PL): {ps_latency/pl_latency:.2f}x")
    print("-" * 40)

    # 4. ASCII Confusion Matrix (10 samples)
    print("\nConfusion Matrix (10 Samples):")
    conf_matrix = np.zeros((10, 10), dtype=int)

    all_images = images.view(10, 784).numpy()
    all_labels = labels.numpy()

    for i in range(10):
        # Run PL inference
        iq = (all_images[i] * 64).clip(-128, 127).astype(np.int8)
        z1 = np.dot(w1_pl.astype(np.int32), iq.astype(np.int32))
        a1 = np.maximum(0, z1)
        z2 = np.dot(w2_pl.astype(np.int32), a1)
        pred = np.argmax(z2)
        conf_matrix[all_labels[i], pred] += 1

    print("      Predicted")
    print("      " + " ".join([f"{i:2}" for i in range(10)]))
    print("      " + "-" * 30)
    for i in range(10):
        row = " ".join([f"{val:2}" if val > 0 else " ." for val in conf_matrix[i]])
        print(f"Act {i} | {row}")

if __name__ == "__main__":
    run_benchmark()
