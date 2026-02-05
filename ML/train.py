import torch
from torch.utils.data import DataLoader
from torch.nn import BCEWithLogitsLoss
from torch.optim import AdamW
from tqdm import tqdm 
from data.dataset import VideoDataset
from models.model import ShopliftingModel
from dotenv import load_dotenv

load_dotenv("keys.env")

"""
This script trains an end-to-end spatiotemporal deep learning
model for shoplifting detection using video clips. 

The model combines: 
    - A CNN-based spatial encoder (EfficientNetV2)
    - A Transformer-based temporal encoder
    - A lightweight binary classifier

Dataset Assumptions
The dataset must be pre-split to avoid data leakage. This was done on AWS S3
beforehand:

    S3 Bucket/
        train/
            normal
            shoplifting
        val/
            normal
            shoplifting
        test/
            normal
            shoplifting

Each video clip represents one training sample.

Training Strategy 

    - The spatial backbone is frozen for the first few epochs
      to stabilize training.
    
    - Afterward, the entire model is fine-tuned end-to-end 
      using different learning rates.

    - Binary classification is optimized using
      BCEWithlogitsLoss.

Hardware Assumptions

    - GPU: NVIDIA RTX 3090 or equivalent
    - Sufficient VRAM for batched video clips

Output

    - Trained model weights are saved as: 'shoplifting_model.pth'

Notes

    - AWS S3 integration is handled separately.
    - Visualization and metrics are added in later stages. 

Evaluation Metrics

During validation, the following metrics are computed:

    - True Positives (TP)
    - False Positives (FP)
    - False Negatives (FN)
    - True Negatives (TN)

Derived Metrics 

    - Precision = TP / (TP + FP)
    - Recall = TP / (TP + FN)
    - F1-score = harmonic mean of precision and recall

Metrics are computed using sigmoid probabilities
with a fixed threshold of 0.5.

These metrics provide insight into:
    - false alarm rate (FP)
    - missed shoplifting events (FN)
which are critical in real-world deployment.
"""

def compute_metrics(logits, labels, threshold = 0.5):
    probs = torch.sigmoid(logits)
    preds = (probs >= threshold).long()

    labels = labels.long()

    TP = ((preds == 1) & (labels == 1)).sum().item()
    FP = ((preds == 1) & (labels == 0)).sum().item()
    FN = ((preds == 0) & (labels == 1)).sum().item()
    TN = ((preds == 0) & (labels == 0)).sum().item()

    precision = TP / (TP + FP + 1e-8)
    recall    = TP / (TP + FN + 1e-8)
    f1        = 2 * precision * recall / (precision + recall + 1e-8)

    return {
        "TP": TP,
        "FP": FP,
        "FN": FN,
        "TN": TN,
        "precision": precision,
        "recall": recall,
        "f1": f1,
    }

TRAIN_DIR = "dataset/trian"
VAL_DIR = "dataset/val"

NUM_FRAMES = 50
BATCH_SIZE_FROZEN = 8
BATCH_SIZE_UNFROZEN = 1
EPOCHS = 20
LR_BACKBONE = 1e-5
LR_HEAD = 1e-4
DEVICE = "cuda"


# def train_one_epoch(model, loader, optimizer, criterion):
#     model.train()
#     total_loss = 0.0

#     for videos, labels in tqdm(loader, desc="Training", leave=False):
#         videos = videos.to(DEVICE)
#         labels = labels.to(DEVICE)

#         optimizer.zero_grad()

#         logits = model(videos)
#         loss = criterion(logits, labels)

#         loss.backward()
#         optimizer.step()

#         total_loss += loss.item()
    
#     return total_loss / len(loader)

def train_one_epoch(model, loader, optimizer, criterion, scaler):
    model.train()
    total_loss = 0.0

    for videos, labels in tqdm(loader, desc="Training", leave=False):
        videos = videos.to(DEVICE, non_blocking=True)
        labels = labels.to(DEVICE, non_blocking=True)

        optimizer.zero_grad(set_to_none=True)

        #  AMP starts here
        with torch.amp.autocast("cuda"):
            logits = model(videos)
            loss = criterion(logits, labels)

        #  scaled backward pass
        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()

        total_loss += loss.item()

    return total_loss / len(loader)

@torch.no_grad()
def validate(model, loader, criterion):
    model.eval()
    total_loss = 0.0
    all_logits = []
    all_labels = []

    for videos, labels in tqdm(loader, desc="Validation", leave=False):
        videos = videos.to(DEVICE)
        labels = labels.to(DEVICE)

        logits = model(videos)
        loss = criterion(logits, labels)

        total_loss += loss.item()
        all_logits.append(logits)
        all_labels.append(labels)

    all_logits = torch.cat(all_logits)
    all_labels = torch.cat(all_labels)

    metrics = compute_metrics(all_logits, all_labels)

    return total_loss / len(loader), metrics

def main():

    train_ds = VideoDataset("manifests/train.txt", NUM_FRAMES)
    val_ds = VideoDataset("manifests/val.txt", NUM_FRAMES)

    train_loader = DataLoader(
        train_ds,
        batch_size=BATCH_SIZE_FROZEN,
        shuffle=True,
        num_workers=4,
        pin_memory=True
    )

    val_loader = DataLoader(
        val_ds,
        batch_size=BATCH_SIZE_UNFROZEN,
        shuffle=False,
        num_workers=4,
        pin_memory=True
    )

    model = ShopliftingModel().to(DEVICE)

    for param in model.spatial.parameters():
        param.requires_grad = False

    optimizer = AdamW([
        {"params": model.temporal.parameters(), "lr":LR_HEAD},
        {"params": model.classifier.parameters(), "lr":LR_BACKBONE},

    ])

    criterion = BCEWithLogitsLoss()
    scaler = torch.amp.GradScaler("cuda")

    for epoch in range(EPOCHS):
        train_loss = train_one_epoch(model, train_loader, optimizer, criterion, scaler)
        val_loss, metrics = validate(model, val_loader, criterion)

        print(
            f"Epoch [ {epoch+1}/{EPOCHS} ] | "
            f"Train Loss: {train_loss:.4f} | "
            f"Val Loss: {val_loss:.4f} | "
            f"Precision: {metrics['precision']:.3f} | "
            f"Recall: {metrics['recall']:.3f} | "
            f"F1: {metrics['f1']:.3f} | "
            f"FP: {metrics['FP']:.3f} | "
            f"FN: {metrics['FN']:.3f} | "
        )

        if epoch == 4:
            print("Unfreezing spatial backbone")
            for name, param in model.spatial.backbone.named_parameters():
                if "blocks.4" not in name and "blocks.5" not in name:
                    param.requires_grad = False

            optimizer = AdamW([
                {"params": model.spatial.parameters(), "lr": LR_BACKBONE},
                {"params": model.temporal.parameters(), "lr": LR_HEAD},
                {"params": model.classifier.parameters(), "lr":LR_HEAD},
            ])

    torch.save(model.state_dict(), "shoplifting_model.pth")
    print("Training Complete, Model saved")

if __name__ == "__main__":
    main()