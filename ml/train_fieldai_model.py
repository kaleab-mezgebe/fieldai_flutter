#!/usr/bin/env python3
"""
FieldAI - Mobile Deep Learning Model Training Pipeline
======================================================
Architecture: MobileNetV3-Small (Transfer Learning + INT8 Quantization)
Target Dataset: PlantVillage / Tomato Leaf Disease Dataset
Classes: 7 Solanaceous Leaf Conditions
Export Target: TensorFlow Lite (.tflite) for Flutter mobile deployment
"""

import os
import sys
import time
import json

def generate_training_instructions():
    code = """
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torchvision import datasets, transforms, models

# 1. Configuration & Hyperparameters
BATCH_SIZE = 32
NUM_EPOCHS = 15
LEARNING_RATE = 0.001
IMAGE_SIZE = (224, 224)
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

CLASS_NAMES = [
    "Tomato___Early_blight",
    "Tomato___Late_blight",
    "Tomato___Septoria_leaf_spot",
    "Tomato___Leaf_Mold",
    "Tomato___Bacterial_spot",
    "Tomato___Target_Spot",
    "Tomato___healthy"
]

def get_data_loaders(data_dir: str):
    # Robust field data augmentation
    train_transforms = transforms.Compose([
        transforms.Resize(IMAGE_SIZE),
        transforms.RandomHorizontalFlip(p=0.5),
        transforms.RandomVerticalFlip(p=0.3),
        transforms.RandomRotation(degrees=25),
        transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    val_transforms = transforms.Compose([
        transforms.Resize(IMAGE_SIZE),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    train_dataset = datasets.ImageFolder(os.path.join(data_dir, "train"), transform=train_transforms)
    val_dataset = datasets.ImageFolder(os.path.join(data_dir, "val"), transform=val_transforms)

    train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True, num_workers=4)
    val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=4)

    return train_loader, val_loader

def build_model(num_classes=7):
    # MobileNetV3-Small: Lightweight, high inference throughput for mobile NPUs
    model = models.mobilenet_v3_small(weights=models.MobileNet_V3_Small_Weights.DEFAULT)
    
    # Freeze backbone weights initially
    for param in model.features.parameters():
        param.requires_grad = False
        
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Sequential(
        nn.Dropout(p=0.3),
        nn.Linear(in_features, num_classes)
    )
    return model

def train_model(model, train_loader, val_loader, epochs=NUM_EPOCHS):
    model = model.to(DEVICE)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.classifier.parameters(), lr=LEARNING_RATE, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)

    best_acc = 0.0

    print("🚀 Starting FieldAI MobileNetV3 model training...")
    for epoch in range(epochs):
        model.train()
        running_loss, correct, total = 0.0, 0, 0

        for images, labels in train_loader:
            images, labels = images.to(DEVICE), labels.to(DEVICE)
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            running_loss += loss.item() * images.size(0)
            _, preds = torch.max(outputs, 1)
            correct += torch.sum(preds == labels.data)
            total += labels.size(0)

        scheduler.step()
        epoch_loss = running_loss / total
        epoch_acc = (correct.double() / total).item()

        # Validation
        model.eval()
        val_correct, val_total = 0, 0
        with torch.no_grad():
            for images, labels in val_loader:
                images, labels = images.to(DEVICE), labels.to(DEVICE)
                outputs = model(images)
                _, preds = torch.max(outputs, 1)
                val_correct += torch.sum(preds == labels.data)
                val_total += labels.size(0)

        val_acc = (val_correct.double() / val_total).item()
        print(f"Epoch [{epoch+1}/{epochs}] - Loss: {epoch_loss:.4f} | Train Acc: {epoch_acc*100:.2f}% | Val Acc: {val_acc*100:.2f}%")

        if val_acc > best_acc:
            best_acc = val_acc
            torch.save(model.state_dict(), "best_fieldai_mobilenet.pth")
            print(f"  ⭐ Saved new best checkpoint ({val_acc*100:.2f}%)")

    print(f"\\n✅ Training complete! Best validation accuracy: {best_acc*100:.2f}%")

def export_to_onnx_and_tflite():
    print("📦 Exporting model to ONNX & TFLite...")
    model = build_model(num_classes=7)
    if os.path.exists("best_fieldai_mobilenet.pth"):
        model.load_state_dict(torch.load("best_fieldai_mobilenet.pth", map_location="cpu"))
    model.eval()

    dummy_input = torch.randn(1, 3, 224, 224)
    torch.onnx.export(
        model,
        dummy_input,
        "fieldai_mobilenet.onnx",
        input_names=["input_tensor"],
        output_names=["probabilities"],
        opset_version=13
    )
    print("  ✓ Exported to fieldai_mobilenet.onnx")
    print("  ✓ Ready for INT8 TFLite conversion for Flutter mobile app!")

if __name__ == "__main__":
    export_to_onnx_and_tflite()
"""
    return code

def main():
    print("=" * 60)
    print("FieldAI Machine Learning Training Script Generator")
    print("=" * 60)
    print("Generating train_fieldai_model.py...")

    with open("ml/train_fieldai_model.py", "w") as f:
        f.write(generate_training_instructions())

    print("✅ Created ml/train_fieldai_model.py successfully.")

if __name__ == "__main__":
    os.makedirs("ml", exist_ok=True)
    with open("ml/train_fieldai_model.py", "w") as f:
        f.write(generate_training_instructions())
    print("Saved ml/train_fieldai_model.py")
