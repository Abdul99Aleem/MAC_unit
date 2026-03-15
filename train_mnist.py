import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader

# 1. Architecture: 784 -> 64 -> 10
class MNISTMLP(nn.Module):
    def __init__(self):
        super(MNISTMLP, self).__init__()
        self.fc1 = nn.Linear(784, 64, bias=False) # No bias as per spec
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(64, 10, bias=False)  # No bias as per spec

    def forward(self, x):
        x = x.view(-1, 784)
        x = self.relu(self.fc1(x))
        x = self.fc2(x)
        return x

def train():
    # 2. Setup
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])

    train_loader = DataLoader(
        datasets.MNIST('./data', train=True, download=True, transform=transform),
        batch_size=64, shuffle=True
    )

    model = MNISTMLP().to(device)
    optimizer = optim.Adam(model.parameters(), lr=0.001)
    criterion = nn.CrossEntropyLoss()

    # 3. Training Loop (5 Epochs)
    model.train()
    for epoch in range(1, 6):
        total_loss = 0
        for batch_idx, (data, target) in enumerate(train_loader):
            data, target = data.to(device), target.to(device)
            optimizer.zero_grad()
            output = model(data)
            loss = criterion(output, target)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()

        print(f"Epoch {epoch}, Average Loss: {total_loss/len(train_loader):.4f}")

    # 4. Symmetric Quantization to INT8
    print("\nQuantizing weights to INT8...")
    state_dict = model.state_dict()
    quantized_state = {}

    for name, param in state_dict.items():
        if 'weight' in name:
            # Symmetric scale: 127 / max(|W|)
            max_val = param.abs().max()
            scale = 127.0 / max_val

            # Quantize: round(W * scale), clamp to [-128, 127]
            q_weight = (param * scale).round().clamp(-128, 127).to(torch.int8)
            quantized_state[name] = q_weight

            print(f"Layer: {name}")
            print(f"  Original range: [{param.min():.4f}, {param.max():.4f}]")
            print(f"  Scale: {scale:.4f}")
            print(f"  Quantized range: [{q_weight.min()}, {q_weight.max()}]")

    # 5. Save quantized model
    torch.save(quantized_state, 'mnist_mlp.pt')
    print("\nQuantized model saved to mnist_mlp.pt")

if __name__ == "__main__":
    train()
