import torch
import os

def to_hex(val):
    """Convert a signed 8-bit integer to a 2-character hex string (2's complement)."""
    return format(int(val) & 0xFF, '02x')

def export():
    # 1. Load the quantized state dict
    if not os.path.exists('mnist_mlp.pt'):
        print("Error: mnist_mlp.pt not found. Run train_mnist.py first.")
        return

    quantized_state = torch.load('mnist_mlp.pt')

    # 2. Export fc1.weight (64 x 784)
    fc1_weight = quantized_state['fc1.weight']
    print(f"Exporting fc1.weight: {fc1_weight.shape}")

    with open('weights_layer1.mem', 'w') as f:
        # Row-major order: iterate rows then columns
        # fc1_weight is (64, 784)
        for i in range(fc1_weight.shape[0]):
            for j in range(fc1_weight.shape[1]):
                val = fc1_weight[i, j].item()
                f.write(f"{to_hex(val)}\n")

    # 3. Export fc2.weight (10 x 64)
    fc2_weight = quantized_state['fc2.weight']
    print(f"Exporting fc2.weight: {fc2_weight.shape}")

    with open('weights_layer2.mem', 'w') as f:
        # Row-major order: iterate rows then columns
        # fc2_weight is (10, 64)
        for i in range(fc2_weight.shape[0]):
            for j in range(fc2_weight.shape[1]):
                val = fc2_weight[i, j].item()
                f.write(f"{to_hex(val)}\n")

    print("\nExport complete!")
    print(f"  weights_layer1.mem: {os.path.getsize('weights_layer1.mem')} bytes approx")
    print(f"  weights_layer2.mem: {os.path.getsize('weights_layer2.mem')} bytes approx")

if __name__ == "__main__":
    export()
