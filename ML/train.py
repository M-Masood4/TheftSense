import torch
from torch.utils.data import DataLoader
from torch.nn import BCEWithLogitsLoss
from torch.optim import AdamW
from tqdm import tqdm 
from data.dataset import VideoDataset
from models.model import ShopliftingModel
from dotenv import load_dotenv
import torch.nn.functional as F
import torch.nn as nn


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

# def compute_metrics(logits, labels, threshold = 0.5):
#     probs = torch.sigmoid(logits)
#     preds = (probs >= threshold).long()

#     labels = labels.long()

#     TP = ((preds == 1) & (labels == 1)).sum().item()
#     FP = ((preds == 1) & (labels == 0)).sum().item()
#     FN = ((preds == 0) & (labels == 1)).sum().item()
#     TN = ((preds == 0) & (labels == 0)).sum().item()

#     precision = TP / (TP + FP + 1e-8)
#     recall    = TP / (TP + FN + 1e-8)
#     f1        = 2 * precision * recall / (precision + recall + 1e-8)

#     return {
#         "TP": TP,
#         "FP": FP,
#         "FN": FN,
#         "TN": TN,
#         "precision": precision,
#         "recall": recall,
#         "f1": f1,
#     }

# TRAIN_DIR = "dataset/trian"
# VAL_DIR = "dataset/val"

# NUM_FRAMES = 50
# BATCH_SIZE_FROZEN = 8
# BATCH_SIZE_UNFROZEN = 1
# EPOCHS = 20
# LR_BACKBONE = 1e-5
# LR_HEAD = 1e-4
# DEVICE = "cuda"

# def train_one_epoch(model, loader, optimizer, criterion, scaler):
#     model.train()
#     total_loss = 0.0

#     for videos, labels in tqdm(loader, desc="Training", leave=False):
#         videos = videos.to(DEVICE, non_blocking=True)
#         labels = labels.to(DEVICE, non_blocking=True)

#         optimizer.zero_grad(set_to_none=True)

#         #  AMP starts here
#         with torch.amp.autocast("cuda"):
#             logits = model(videos)
#             loss = criterion(logits, labels)

#         #  scaled backward pass
#         scaler.scale(loss).backward()
#         scaler.step(optimizer)
#         scaler.update()

#         total_loss += loss.item()

#     return total_loss / len(loader)

# @torch.no_grad()
# def validate(model, loader, criterion):
#     model.eval()
#     total_loss = 0.0
#     all_logits = []
#     all_labels = []

#     for videos, labels in tqdm(loader, desc="Validation", leave=False):
#         videos = videos.to(DEVICE)
#         labels = labels.to(DEVICE)

#         logits = model(videos)
#         loss = criterion(logits, labels)

#         total_loss += loss.item()
#         all_logits.append(logits)
#         all_labels.append(labels)

#     all_logits = torch.cat(all_logits)
#     all_labels = torch.cat(all_labels)

#     metrics = compute_metrics(all_logits, all_labels)

#     return total_loss / len(loader), metrics

# def main():

#     train_ds = VideoDataset("manifests/train.txt", NUM_FRAMES)
#     val_ds = VideoDataset("manifests/val.txt", NUM_FRAMES)

#     train_loader = DataLoader(
#         train_ds,
#         batch_size=BATCH_SIZE_FROZEN,
#         shuffle=True,
#         num_workers=4,
#         pin_memory=True
#     )

#     val_loader = DataLoader(
#         val_ds,
#         batch_size=BATCH_SIZE_UNFROZEN,
#         shuffle=False,
#         num_workers=4,
#         pin_memory=True
#     )

#     model = ShopliftingModel().to(DEVICE)

#     for param in model.spatial.parameters():
#         param.requires_grad = False

#     optimizer = AdamW([
#         {"params": model.temporal.parameters(), "lr":LR_HEAD},
#         {"params": model.classifier.parameters(), "lr":LR_BACKBONE},

#     ])

#     criterion = BCEWithLogitsLoss()
#     scaler = torch.amp.GradScaler("cuda")

#     for epoch in range(EPOCHS):
#         train_loss = train_one_epoch(model, train_loader, optimizer, criterion, scaler)
#         val_loss, metrics = validate(model, val_loader, criterion)

#         print(
#             f"Epoch [ {epoch+1}/{EPOCHS} ] | "
#             f"Train Loss: {train_loss:.4f} | "
#             f"Val Loss: {val_loss:.4f} | "
#             f"Precision: {metrics['precision']:.3f} | "
#             f"Recall: {metrics['recall']:.3f} | "
#             f"F1: {metrics['f1']:.3f} | "
#             f"FP: {metrics['FP']:.3f} | "
#             f"FN: {metrics['FN']:.3f} | "
#         )

#         if epoch == 4:
#             print("Unfreezing spatial backbone")
#             for name, param in model.spatial.backbone.named_parameters():
#                 if "blocks.4" not in name and "blocks.5" not in name:
#                     param.requires_grad = False

#             optimizer = AdamW([
#                 {"params": model.spatial.parameters(), "lr": LR_BACKBONE},
#                 {"params": model.temporal.parameters(), "lr": LR_HEAD},
#                 {"params": model.classifier.parameters(), "lr":LR_HEAD},
#             ])

#     torch.save(model.state_dict(), "shoplifting_model.pth")
#     print("Training Complete, Model saved")

"""
Results:

Epoch [ 1/20 ] | Train Loss: 0.5782 | Val Loss: 0.5372 | Precision: 0.710 | Recall: 0.615 | F1: 0.659 | FP: 47.000 | FN: 72.000 | 
Epoch [ 2/20 ] | Train Loss: 0.5087 | Val Loss: 0.5248 | Precision: 0.773 | Recall: 0.529 | F1: 0.629 | FP: 29.000 | FN: 88.000 | 
Epoch [ 3/20 ] | Train Loss: 0.4868 | Val Loss: 0.5354 | Precision: 0.644 | Recall: 0.824 | F1: 0.723 | FP: 85.000 | FN: 33.000 | 
Epoch [ 4/20 ] | Train Loss: 0.4633 | Val Loss: 0.4881 | Precision: 0.703 | Recall: 0.647 | F1: 0.674 | FP: 51.000 | FN: 66.000 | 
Epoch [ 5/20 ] | Train Loss: 0.4629 | Val Loss: 0.5107 | Precision: 0.699 | Recall: 0.695 | F1: 0.697 | FP: 56.000 | FN: 57.000 | 
Unfreezing spatial backbone 
Epoch [ 6/20 ] | Train Loss: 0.4378 | Val Loss: 0.5069 | Precision: 0.685 | Recall: 0.663 | F1: 0.674 | FP: 57.000 | FN: 63.000 | 
Epoch [ 7/20 ] | Train Loss: 0.3944 | Val Loss: 0.5332 | Precision: 0.698 | Recall: 0.679 | F1: 0.688 | FP: 55.000 | FN: 60.000 | 
Epoch [ 8/20 ] | Train Loss: 0.4021 | Val Loss: 0.5040 | Precision: 0.770 | Recall: 0.572 | F1: 0.656 | FP: 32.000 | FN: 80.000 | 
Epoch [ 9/20 ] | Train Loss: 0.3749 | Val Loss: 0.6050 | Precision: 0.684 | Recall: 0.717 | F1: 0.700 | FP: 62.000 | FN: 53.000 | 
Epoch [ 10/20 ] | Train Loss: 0.3814 | Val Loss: 0.5693 | Precision: 0.697 | Recall: 0.652 | F1: 0.674 | FP: 53.000 | FN: 65.000 | 
Epoch [ 11/20 ] | Train Loss: 0.3838 | Val Loss: 0.5400 | Precision: 0.748 | Recall: 0.588 | F1: 0.659 | FP: 37.000 | FN: 77.000 | 
Epoch [ 12/20 ] | Train Loss: 0.3367 | Val Loss: 0.6855 | Precision: 0.657 | Recall: 0.727 | F1: 0.690 | FP: 71.000 | FN: 51.000 | 
Epoch [ 13/20 ] | Train Loss: 0.3016 | Val Loss: 0.5683 | Precision: 0.798 | Recall: 0.487 | F1: 0.605 | FP: 23.000 | FN: 96.000 | 
Epoch [ 14/20 ] | Train Loss: 0.3486 | Val Loss: 0.6757 | Precision: 0.752 | Recall: 0.487 | F1: 0.591 | FP: 30.000 | FN: 96.000 | 
Epoch [ 15/20 ] | Train Loss: 0.2903 | Val Loss: 0.6318 | Precision: 0.665 | Recall: 0.711 | F1: 0.687 | FP: 67.000 | FN: 54.000 | 
Epoch [ 16/20 ] | Train Loss: 0.3204 | Val Loss: 0.5640 | Precision: 0.726 | Recall: 0.610 | F1: 0.663 | FP: 43.000 | FN: 73.000 | 
Epoch [ 17/20 ] | Train Loss: 0.3287 | Val Loss: 0.6332 | Precision: 0.697 | Recall: 0.690 | F1: 0.694 | FP: 56.000 | FN: 58.000 | 
Epoch [ 18/20 ] | Train Loss: 0.2931 | Val Loss: 0.5760 | Precision: 0.681 | Recall: 0.695 | F1: 0.688 | FP: 61.000 | FN: 57.000 | 
Epoch [ 19/20 ] | Train Loss: 0.2928 | Val Loss: 0.6773 | Precision: 0.704 | Recall: 0.572 | F1: 0.631 | FP: 45.000 | FN: 80.000 | 
Epoch [ 20/20 ] | Train Loss: 0.3059 | Val Loss: 0.6803 | Precision: 0.692 | Recall: 0.674 | F1: 0.683 | FP: 56.000 | FN: 61.000 | 

Here, our model gets upto ~69% precision, this means that there are 31% false alarms. Recall is ~67%, i.e. 33% cases of shoplifting
were missed. 

F1 Score is 68%, means model is decent in catching shoplifting as well as not raising false positives. Although this can be improved. 
This is the main focus of our model, improving the F1 score.

"""

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------


"""
Changes made to the model after results: 

    - models/temporal.py: Transformer encoder with positional encoding for temporal modelling.
    - models/model.py: End-to-end spatiometer model with updated transformer and classifier.
    - train.py: class weighted BCE

"""


# def compute_metrics(logits, labels, threshold = 0.5):
#     probs = torch.sigmoid(logits)
#     preds = (probs >= threshold).long()

#     labels = labels.long()

#     TP = ((preds == 1) & (labels == 1)).sum().item()
#     FP = ((preds == 1) & (labels == 0)).sum().item()
#     FN = ((preds == 0) & (labels == 1)).sum().item()
#     TN = ((preds == 0) & (labels == 0)).sum().item()

#     precision = TP / (TP + FP + 1e-8)
#     recall    = TP / (TP + FN + 1e-8)
#     f1        = 2 * precision * recall / (precision + recall + 1e-8)

#     return {
#         "TP": TP,
#         "FP": FP,
#         "FN": FN,
#         "TN": TN,
#         "precision": precision,
#         "recall": recall,
#         "f1": f1,
#     }

# TRAIN_DIR = "dataset/trian"
# VAL_DIR = "dataset/val"

# NUM_FRAMES = 50
# BATCH_SIZE_FROZEN = 8
# BATCH_SIZE_UNFROZEN = 1
# EPOCHS = 20
# LR_BACKBONE = 1e-5
# LR_HEAD = 1e-4
# DEVICE = "cuda"

# def train_one_epoch(model, loader, optimizer, criterion, scaler):
#     model.train()
#     total_loss = 0.0

#     for videos, labels in tqdm(loader, desc="Training", leave=False):
#         videos = videos.to(DEVICE, non_blocking=True)
#         labels = labels.to(DEVICE, non_blocking=True)

#         optimizer.zero_grad(set_to_none=True)

#         #  AMP starts here
#         with torch.amp.autocast("cuda"):
#             logits = model(videos)
#             loss = criterion(logits, labels)

#         #  scaled backward pass
#         scaler.scale(loss).backward()
#         scaler.step(optimizer)
#         scaler.update()

#         total_loss += loss.item()

#     return total_loss / len(loader)

# @torch.no_grad()
# def validate(model, loader, criterion):
#     model.eval()
#     total_loss = 0.0
#     all_logits = []
#     all_labels = []

#     for videos, labels in tqdm(loader, desc="Validation", leave=False):
#         videos = videos.to(DEVICE)
#         labels = labels.to(DEVICE)

#         logits = model(videos)
#         loss = criterion(logits, labels)

#         total_loss += loss.item()
#         all_logits.append(logits)
#         all_labels.append(labels)

#     all_logits = torch.cat(all_logits)
#     all_labels = torch.cat(all_labels)

#     metrics = compute_metrics(all_logits, all_labels)

#     return total_loss / len(loader), metrics

# def main():

#     train_ds = VideoDataset("manifests/train.txt", NUM_FRAMES)
#     val_ds = VideoDataset("manifests/val.txt", NUM_FRAMES)

#     train_loader = DataLoader(
#         train_ds,
#         batch_size=BATCH_SIZE_FROZEN,
#         shuffle=True,
#         num_workers=4,
#         pin_memory=True
#     )

#     val_loader = DataLoader(
#         val_ds,
#         batch_size=BATCH_SIZE_UNFROZEN,
#         shuffle=False,
#         num_workers=4,
#         pin_memory=True
#     )

#     model = ShopliftingModel().to(DEVICE)

#     for param in model.spatial.parameters():
#         param.requires_grad = False

#     num_normal = sum(1 for _, l in train_ds.samples if l == 0)
#     num_shoplifting = sum(1 for _, l in train_ds.samples if l == 1)
#     pos_weight = torch.tensor(num_normal / (num_shoplifting + 1e-8)).to(DEVICE)


#     criterion = BCEWithLogitsLoss(pos_weight=pos_weight)

#     optimizer = AdamW([
#         {"params": model.temporal.parameters(), "lr":1e-4},
#         {"params": model.classifier.parameters(), "lr":1e-4},

#     ])

#     scaler = torch.amp.GradScaler("cuda")

#     for epoch in range(EPOCHS):
#         train_loss = train_one_epoch(model, train_loader, optimizer, criterion, scaler)
#         val_loss, metrics = validate(model, val_loader, criterion)

#         print(
#             f"Epoch [ {epoch+1}/{EPOCHS} ] | "
#             f"Train Loss: {train_loss:.4f} | "
#             f"Val Loss: {val_loss:.4f} | "
#             f"Precision: {metrics['precision']:.3f} | "
#             f"Recall: {metrics['recall']:.3f} | "
#             f"F1: {metrics['f1']:.3f} | "
#             f"FP: {metrics['FP']:.3f} | "
#             f"FN: {metrics['FN']:.3f} | "
#         )

#         if epoch == 4:
#             print("Unfreezing spatial backbone")
#             for name, param in model.spatial.backbone.named_parameters():
#                 if "blocks.4" not in name and "blocks.5" not in name:
#                     param.requires_grad = False

#             optimizer = AdamW([
#                 {"params": model.spatial.parameters(), "lr": 1e-5},
#                 {"params": model.temporal.parameters(), "lr": 1e-4},
#                 {"params": model.classifier.parameters(), "lr":1e-4},
#             ])

#     torch.save(model.state_dict(), "shoplifting_model_improved.pth")
#     print("Training Complete, Model saved")

"""
Results:

Epoch [ 1/20 ] | Train Loss: 0.7001 | Val Loss: 0.6666 | Precision: 0.693 | Recall: 0.652 | F1: 0.672 | FP: 54.000 | FN: 65.000 |                                                          
Epoch [ 2/20 ] | Train Loss: 0.6418 | Val Loss: 0.6973 | Precision: 0.633 | Recall: 0.775 | F1: 0.697 | FP: 84.000 | FN: 42.000 |                                                          
Epoch [ 3/20 ] | Train Loss: 0.5997 | Val Loss: 0.6871 | Precision: 0.588 | Recall: 0.807 | F1: 0.680 | FP: 106.000 | FN: 36.000 |                                                         
Epoch [ 4/20 ] | Train Loss: 0.5846 | Val Loss: 0.7003 | Precision: 0.536 | Recall: 0.872 | F1: 0.664 | FP: 141.000 | FN: 24.000 |                                                         
Epoch [ 5/20 ] | Train Loss: 0.5216 | Val Loss: 0.6670 | Precision: 0.673 | Recall: 0.738 | F1: 0.704 | FP: 67.000 | FN: 49.000 |                                                          
Unfreezing spatial backbone
Epoch [ 6/20 ] | Train Loss: 0.5574 | Val Loss: 0.8136 | Precision: 0.618 | Recall: 0.754 | F1: 0.680 | FP: 87.000 | FN: 46.000 |                                                          
Epoch [ 7/20 ] | Train Loss: 0.5083 | Val Loss: 0.6633 | Precision: 0.657 | Recall: 0.759 | F1: 0.705 | FP: 74.000 | FN: 45.000 |                                                          
Epoch [ 8/20 ] | Train Loss: 0.4842 | Val Loss: 0.7038 | Precision: 0.716 | Recall: 0.647 | F1: 0.680 | FP: 48.000 | FN: 66.000 |                                                          
Epoch [ 9/20 ] | Train Loss: 0.4948 | Val Loss: 0.7195 | Precision: 0.671 | Recall: 0.743 | F1: 0.706 | FP: 68.000 | FN: 48.000 |                                                          
Epoch [ 10/20 ] | Train Loss: 0.4596 | Val Loss: 0.7600 | Precision: 0.581 | Recall: 0.840 | F1: 0.687 | FP: 113.000 | FN: 30.000 |                                                        
Epoch [ 11/20 ] | Train Loss: 0.5353 | Val Loss: 0.7223 | Precision: 0.571 | Recall: 0.834 | F1: 0.678 | FP: 117.000 | FN: 31.000 |                                                        
Epoch [ 12/20 ] | Train Loss: 0.4717 | Val Loss: 0.7749 | Precision: 0.665 | Recall: 0.733 | F1: 0.697 | FP: 69.000 | FN: 50.000 |                                                         
Epoch [ 13/20 ] | Train Loss: 0.4590 | Val Loss: 0.7784 | Precision: 0.561 | Recall: 0.888 | F1: 0.687 | FP: 130.000 | FN: 21.000 |                                                        
Epoch [ 14/20 ] | Train Loss: 0.3931 | Val Loss: 0.8091 | Precision: 0.562 | Recall: 0.872 | F1: 0.683 | FP: 127.000 | FN: 24.000 |                                                        
Epoch [ 15/20 ] | Train Loss: 0.4229 | Val Loss: 0.7318 | Precision: 0.609 | Recall: 0.717 | F1: 0.658 | FP: 86.000 | FN: 53.000 |                                                         
Epoch [ 16/20 ] | Train Loss: 0.4171 | Val Loss: 0.8064 | Precision: 0.688 | Recall: 0.626 | F1: 0.655 | FP: 53.000 | FN: 70.000 |                                                         
Epoch [ 17/20 ] | Train Loss: 0.4006 | Val Loss: 0.9330 | Precision: 0.670 | Recall: 0.663 | F1: 0.667 | FP: 61.000 | FN: 63.000 |                                                         
Epoch [ 18/20 ] | Train Loss: 0.3742 | Val Loss: 0.8476 | Precision: 0.650 | Recall: 0.706 | F1: 0.677 | FP: 71.000 | FN: 55.000 |                                                         
Epoch [ 19/20 ] | Train Loss: 0.3826 | Val Loss: 0.9050 | Precision: 0.717 | Recall: 0.583 | F1: 0.643 | FP: 43.000 | FN: 78.000 |                                                         
Epoch [ 20/20 ] | Train Loss: 0.3546 | Val Loss: 1.0246 | Precision: 0.816 | Recall: 0.214 | F1: 0.339 | FP: 9.000 | FN: 147.000 |                                                         
Training Complete, Model saved

Best epochs (by F1): 5-9

After that, validation loss goes up, F1 oscillates, precision and recall trade violently and final epoch collapses. 
This is classic overfitting after unfreezing. 

This happens when:

    - Learning rates are too high
    - No regularization/early stopping 

"""

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------

"""
Changes made after above results:

    - train.py: Reduced learning rate after unfreeze
    - train.py: Threshold tuning to 0.35
"""


# def compute_metrics(logits, labels, threshold = 0.35):
#     probs = torch.sigmoid(logits)
#     preds = (probs >= threshold).long()

#     labels = labels.long()

#     TP = ((preds == 1) & (labels == 1)).sum().item()
#     FP = ((preds == 1) & (labels == 0)).sum().item()
#     FN = ((preds == 0) & (labels == 1)).sum().item()
#     TN = ((preds == 0) & (labels == 0)).sum().item()

#     precision = TP / (TP + FP + 1e-8)
#     recall    = TP / (TP + FN + 1e-8)
#     f1        = 2 * precision * recall / (precision + recall + 1e-8)

#     return {
#         "TP": TP,
#         "FP": FP,
#         "FN": FN,
#         "TN": TN,
#         "precision": precision,
#         "recall": recall,
#         "f1": f1,
#     }

# TRAIN_DIR = "dataset/trian"
# VAL_DIR = "dataset/val"

# NUM_FRAMES = 50
# BATCH_SIZE_FROZEN = 8
# BATCH_SIZE_UNFROZEN = 1
# EPOCHS = 20
# LR_BACKBONE = 1e-5
# LR_HEAD = 1e-4
# DEVICE = "cuda"

# def train_one_epoch(model, loader, optimizer, criterion, scaler):
#     model.train()
#     total_loss = 0.0

#     for videos, labels in tqdm(loader, desc="Training", leave=False):
#         videos = videos.to(DEVICE, non_blocking=True)
#         labels = labels.to(DEVICE, non_blocking=True)

#         optimizer.zero_grad(set_to_none=True)

#         #  AMP starts here
#         with torch.amp.autocast("cuda"):
#             logits = model(videos)
#             loss = criterion(logits, labels)

#         #  scaled backward pass
#         scaler.scale(loss).backward()
#         scaler.step(optimizer)
#         scaler.update()

#         total_loss += loss.item()

#     return total_loss / len(loader)

# @torch.no_grad()
# def validate(model, loader, criterion):
#     model.eval()
#     total_loss = 0.0
#     all_logits = []
#     all_labels = []

#     for videos, labels in tqdm(loader, desc="Validation", leave=False):
#         videos = videos.to(DEVICE)
#         labels = labels.to(DEVICE)

#         logits = model(videos)
#         loss = criterion(logits, labels)

#         total_loss += loss.item()
#         all_logits.append(logits)
#         all_labels.append(labels)

#     all_logits = torch.cat(all_logits)
#     all_labels = torch.cat(all_labels)

#     metrics = compute_metrics(all_logits, all_labels)

#     return total_loss / len(loader), metrics

# def main():

#     train_ds = VideoDataset("manifests/train.txt", NUM_FRAMES)
#     val_ds = VideoDataset("manifests/val.txt", NUM_FRAMES)

#     train_loader = DataLoader(
#         train_ds,
#         batch_size=BATCH_SIZE_FROZEN,
#         shuffle=True,
#         num_workers=4,
#         pin_memory=True
#     )

#     val_loader = DataLoader(
#         val_ds,
#         batch_size=BATCH_SIZE_UNFROZEN,
#         shuffle=False,
#         num_workers=4,
#         pin_memory=True
#     )

#     model = ShopliftingModel().to(DEVICE)

#     for param in model.spatial.parameters():
#         param.requires_grad = False

#     num_normal = sum(1 for _, l in train_ds.samples if l == 0)
#     num_shoplifting = sum(1 for _, l in train_ds.samples if l == 1)
#     pos_weight = torch.tensor(num_normal / (num_shoplifting + 1e-8)).to(DEVICE)


#     criterion = BCEWithLogitsLoss(pos_weight=pos_weight)

#     optimizer = AdamW([
#         {"params": model.temporal.parameters(), "lr":1e-4},
#         {"params": model.classifier.parameters(), "lr":1e-4},

#     ])

#     scaler = torch.amp.GradScaler("cuda")

#     for epoch in range(EPOCHS):
#         train_loss = train_one_epoch(model, train_loader, optimizer, criterion, scaler)
#         val_loss, metrics = validate(model, val_loader, criterion)

#         print(
#             f"Epoch [ {epoch+1}/{EPOCHS} ] | "
#             f"Train Loss: {train_loss:.4f} | "
#             f"Val Loss: {val_loss:.4f} | "
#             f"Precision: {metrics['precision']:.3f} | "
#             f"Recall: {metrics['recall']:.3f} | "
#             f"F1: {metrics['f1']:.3f} | "
#             f"FP: {metrics['FP']:.3f} | "
#             f"FN: {metrics['FN']:.3f} | "
#         )

#         if epoch == 4:
#             print("Unfreezing spatial backbone")
#             for g in optimizer.param_groups:
#                 g['lr'] *= 0.1
#             for name, param in model.spatial.backbone.named_parameters():
#                 if "blocks.4" not in name and "blocks.5" not in name:
#                     param.requires_grad = False

#             optimizer = AdamW([
#                 {"params": model.spatial.parameters(), "lr": 1e-5},
#                 {"params": model.temporal.parameters(), "lr": 1e-4},
#                 {"params": model.classifier.parameters(), "lr":1e-4},
#             ])

#     torch.save(model.state_dict(), "shoplifting_model_v3.pth")
#     print("Training Complete, Model saved")

"""
Results: 

Epoch [ 1/20 ] | Train Loss: 0.6987 | Val Loss: 0.6613 | Precision: 0.488 | Recall: 0.952 | F1: 0.645 | FP: 187.000 | FN: 9.000 |                                                          
Epoch [ 2/20 ] | Train Loss: 0.6399 | Val Loss: 0.6639 | Precision: 0.532 | Recall: 0.893 | F1: 0.667 | FP: 147.000 | FN: 20.000 |                                                         
Epoch [ 3/20 ] | Train Loss: 0.5830 | Val Loss: 0.6124 | Precision: 0.568 | Recall: 0.898 | F1: 0.696 | FP: 128.000 | FN: 19.000 |                                                         
Epoch [ 4/20 ] | Train Loss: 0.5533 | Val Loss: 0.7378 | Precision: 0.625 | Recall: 0.749 | F1: 0.681 | FP: 84.000 | FN: 47.000 |                                                          
Epoch [ 5/20 ] | Train Loss: 0.5757 | Val Loss: 0.6760 | Precision: 0.581 | Recall: 0.845 | F1: 0.688 | FP: 114.000 | FN: 29.000 |                                                         
Unfreezing spatial backbone
Epoch [ 6/20 ] | Train Loss: 0.5422 | Val Loss: 0.6660 | Precision: 0.550 | Recall: 0.914 | F1: 0.687 | FP: 140.000 | FN: 16.000 |                                                         
Epoch [ 7/20 ] | Train Loss: 0.5222 | Val Loss: 0.6605 | Precision: 0.503 | Recall: 0.930 | F1: 0.653 | FP: 172.000 | FN: 13.000 |                                                         
Epoch [ 8/20 ] | Train Loss: 0.4905 | Val Loss: 0.7494 | Precision: 0.647 | Recall: 0.754 | F1: 0.696 | FP: 77.000 | FN: 46.000 |                                                          
Epoch [ 9/20 ] | Train Loss: 0.4911 | Val Loss: 0.7072 | Precision: 0.632 | Recall: 0.807 | F1: 0.709 | FP: 88.000 | FN: 36.000 |                                                          
Epoch [ 10/20 ] | Train Loss: 0.4714 | Val Loss: 0.8538 | Precision: 0.620 | Recall: 0.802 | F1: 0.699 | FP: 92.000 | FN: 37.000 |                                                         
Epoch [ 11/20 ] | Train Loss: 0.4353 | Val Loss: 0.6738 | Precision: 0.567 | Recall: 0.856 | F1: 0.682 | FP: 122.000 | FN: 27.000 |                                                        
Epoch [ 12/20 ] | Train Loss: 0.4106 | Val Loss: 0.7777 | Precision: 0.611 | Recall: 0.797 | F1: 0.691 | FP: 95.000 | FN: 38.000 |                                                         
Epoch [ 13/20 ] | Train Loss: 0.4036 | Val Loss: 0.8341 | Precision: 0.578 | Recall: 0.856 | F1: 0.690 | FP: 117.000 | FN: 27.000 |                                                        
Epoch [ 14/20 ] | Train Loss: 0.4308 | Val Loss: 0.6905 | Precision: 0.614 | Recall: 0.824 | F1: 0.703 | FP: 97.000 | FN: 33.000 |                                                         
Epoch [ 15/20 ] | Train Loss: 0.4177 | Val Loss: 1.0164 | Precision: 0.674 | Recall: 0.674 | F1: 0.674 | FP: 61.000 | FN: 61.000 |                                                         
Epoch [ 16/20 ] | Train Loss: 0.4086 | Val Loss: 0.8042 | Precision: 0.591 | Recall: 0.834 | F1: 0.692 | FP: 108.000 | FN: 31.000 |                                                        
Epoch [ 17/20 ] | Train Loss: 0.4404 | Val Loss: 0.8543 | Precision: 0.611 | Recall: 0.824 | F1: 0.702 | FP: 98.000 | FN: 33.000 |                                                         
Epoch [ 18/20 ] | Train Loss: 0.4254 | Val Loss: 0.7611 | Precision: 0.617 | Recall: 0.802 | F1: 0.698 | FP: 93.000 | FN: 37.000 |                                                         
Epoch [ 19/20 ] | Train Loss: 0.3596 | Val Loss: 0.9561 | Precision: 0.699 | Recall: 0.658 | F1: 0.678 | FP: 53.000 | FN: 64.000 |                                                         
Epoch [ 20/20 ] | Train Loss: 0.3578 | Val Loss: 1.1909 | Precision: 0.689 | Recall: 0.594 | F1: 0.638 | FP: 50.000 | FN: 76.000 |                                                         
Training Complete, Model saved

After threshold caliberation, the model prioritizes recall (~0.8), significantly reducing missed shoplifting events. However,
overlapping motion characteristics between normal and shoplifting activities limit precision, resulting in an F1 score stabilizing
around 0.65-0.70

"""

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


"""
Changes made after above results: 

    - models/temporal.py: Attention-weighted temporal pooling.
    - analysis/prediction_analysis.py: Used smoothed distributions
"""

# def compute_metrics(logits, labels, threshold = 0.35):
#     probs = torch.sigmoid(logits)
#     preds = (probs >= threshold).long()

#     labels = labels.long()

#     TP = ((preds == 1) & (labels == 1)).sum().item()
#     FP = ((preds == 1) & (labels == 0)).sum().item()
#     FN = ((preds == 0) & (labels == 1)).sum().item()
#     TN = ((preds == 0) & (labels == 0)).sum().item()

#     precision = TP / (TP + FP + 1e-8)
#     recall    = TP / (TP + FN + 1e-8)
#     f1        = 2 * precision * recall / (precision + recall + 1e-8)

#     return {
#         "TP": TP,
#         "FP": FP,
#         "FN": FN,
#         "TN": TN,
#         "precision": precision,
#         "recall": recall,
#         "f1": f1,
#     }

# TRAIN_DIR = "dataset/trian"
# VAL_DIR = "dataset/val"

# NUM_FRAMES = 50
# BATCH_SIZE_FROZEN = 8
# BATCH_SIZE_UNFROZEN = 1
# EPOCHS = 20
# LR_BACKBONE = 1e-5
# LR_HEAD = 1e-4
# DEVICE = "cuda"

# def train_one_epoch(model, loader, optimizer, criterion, scaler):
#     model.train()
#     total_loss = 0.0

#     for videos, labels in tqdm(loader, desc="Training", leave=False):
#         videos = videos.to(DEVICE, non_blocking=True)
#         labels = labels.to(DEVICE, non_blocking=True)

#         optimizer.zero_grad(set_to_none=True)

#         #  AMP starts here
#         with torch.amp.autocast("cuda"):
#             logits = model(videos)
#             loss = criterion(logits, labels)

#         #  scaled backward pass
#         scaler.scale(loss).backward()
#         scaler.step(optimizer)
#         scaler.update()

#         total_loss += loss.item()

#     return total_loss / len(loader)

# @torch.no_grad()
# def validate(model, loader, criterion):
#     model.eval()
#     total_loss = 0.0
#     all_logits = []
#     all_labels = []

#     for videos, labels in tqdm(loader, desc="Validation", leave=False):
#         videos = videos.to(DEVICE)
#         labels = labels.to(DEVICE)

#         logits = model(videos)
#         loss = criterion(logits, labels)

#         total_loss += loss.item()
#         all_logits.append(logits)
#         all_labels.append(labels)

#     all_logits = torch.cat(all_logits)
#     all_labels = torch.cat(all_labels)

#     metrics = compute_metrics(all_logits, all_labels)

#     return total_loss / len(loader), metrics

# def main():

#     train_ds = VideoDataset("manifests/train.txt", NUM_FRAMES)
#     val_ds = VideoDataset("manifests/val.txt", NUM_FRAMES)

#     train_loader = DataLoader(
#         train_ds,
#         batch_size=BATCH_SIZE_FROZEN,
#         shuffle=True,
#         num_workers=4,
#         pin_memory=True
#     )

#     val_loader = DataLoader(
#         val_ds,
#         batch_size=BATCH_SIZE_UNFROZEN,
#         shuffle=False,
#         num_workers=4,
#         pin_memory=True
#     )

#     model = ShopliftingModel().to(DEVICE)

#     for param in model.spatial.parameters():
#         param.requires_grad = False

#     num_normal = sum(1 for _, l in train_ds.samples if l == 0)
#     num_shoplifting = sum(1 for _, l in train_ds.samples if l == 1)
#     pos_weight = torch.tensor(num_normal / (num_shoplifting + 1e-8)).to(DEVICE)


#     criterion = BCEWithLogitsLoss(pos_weight=pos_weight)

#     optimizer = AdamW([
#         {"params": model.temporal.parameters(), "lr":1e-4},
#         {"params": model.classifier.parameters(), "lr":1e-4},

#     ])

#     scaler = torch.amp.GradScaler("cuda")

#     for epoch in range(EPOCHS):
#         train_loss = train_one_epoch(model, train_loader, optimizer, criterion, scaler)
#         val_loss, metrics = validate(model, val_loader, criterion)

#         print(
#             f"Epoch [ {epoch+1}/{EPOCHS} ] | "
#             f"Train Loss: {train_loss:.4f} | "
#             f"Val Loss: {val_loss:.4f} | "
#             f"Precision: {metrics['precision']:.3f} | "
#             f"Recall: {metrics['recall']:.3f} | "
#             f"F1: {metrics['f1']:.3f} | "
#             f"FP: {metrics['FP']:.3f} | "
#             f"FN: {metrics['FN']:.3f} | "
#         )

#         if epoch == 4:
#             print("Unfreezing spatial backbone")
#             for g in optimizer.param_groups:
#                 g['lr'] *= 0.1
#             for name, param in model.spatial.backbone.named_parameters():
#                 if "blocks.4" not in name and "blocks.5" not in name:
#                     param.requires_grad = False

#             optimizer = AdamW([
#                 {"params": model.spatial.parameters(), "lr": 1e-5},
#                 {"params": model.temporal.parameters(), "lr": 1e-4},
#                 {"params": model.classifier.parameters(), "lr":1e-4},
#             ])

#     torch.save(model.state_dict(), "shoplifting_model_v4.pth")
#     print("Training Complete, Model saved")


# if __name__ == "__main__":
#     main()

"""
Epoch [ 1/20 ] | Train Loss: 0.6874 | Val Loss: 0.6776 | Precision: 0.489 | Recall: 0.936 | F1: 0.642 | FP: 183.000 | FN: 12.000 |                                                                                         
Epoch [ 2/20 ] | Train Loss: 0.6142 | Val Loss: 0.6583 | Precision: 0.511 | Recall: 0.861 | F1: 0.641 | FP: 154.000 | FN: 26.000 |                                                                                         
Epoch [ 3/20 ] | Train Loss: 0.5877 | Val Loss: 0.6723 | Precision: 0.621 | Recall: 0.797 | F1: 0.698 | FP: 91.000 | FN: 38.000 |                                                                                          
Epoch [ 4/20 ] | Train Loss: 0.5603 | Val Loss: 0.7014 | Precision: 0.550 | Recall: 0.882 | F1: 0.678 | FP: 135.000 | FN: 22.000 |                                                                                         
Epoch [ 5/20 ] | Train Loss: 0.5249 | Val Loss: 0.6827 | Precision: 0.540 | Recall: 0.904 | F1: 0.676 | FP: 144.000 | FN: 18.000 |                                                                                         
Unfreezing spatial backbone
Epoch [ 6/20 ] | Train Loss: 0.5297 | Val Loss: 0.8957 | Precision: 0.651 | Recall: 0.658 | F1: 0.654 | FP: 66.000 | FN: 64.000 |                                                                                          
Epoch [ 7/20 ] | Train Loss: 0.5112 | Val Loss: 0.8013 | Precision: 0.444 | Recall: 0.984 | F1: 0.612 | FP: 230.000 | FN: 3.000 |                                                                                          
Epoch [ 8/20 ] | Train Loss: 0.5316 | Val Loss: 0.7002 | Precision: 0.558 | Recall: 0.904 | F1: 0.690 | FP: 134.000 | FN: 18.000 |                                                                                         
Epoch [ 9/20 ] | Train Loss: 0.4370 | Val Loss: 0.7790 | Precision: 0.567 | Recall: 0.882 | F1: 0.690 | FP: 126.000 | FN: 22.000 |                                                                                         
Epoch [ 10/20 ] | Train Loss: 0.4458 | Val Loss: 0.9698 | Precision: 0.557 | Recall: 0.882 | F1: 0.683 | FP: 131.000 | FN: 22.000 |                                                                                        
Epoch [ 11/20 ] | Train Loss: 0.4748 | Val Loss: 0.7020 | Precision: 0.533 | Recall: 0.914 | F1: 0.673 | FP: 150.000 | FN: 16.000 |                                                                                        
Epoch [ 12/20 ] | Train Loss: 0.4439 | Val Loss: 0.8814 | Precision: 0.538 | Recall: 0.872 | F1: 0.665 | FP: 140.000 | FN: 24.000 |                                                                                        
Epoch [ 13/20 ] | Train Loss: 0.4235 | Val Loss: 0.9346 | Precision: 0.577 | Recall: 0.818 | F1: 0.677 | FP: 112.000 | FN: 34.000 |                                                                                        
Epoch [ 14/20 ] | Train Loss: 0.4203 | Val Loss: 0.7824 | Precision: 0.544 | Recall: 0.861 | F1: 0.667 | FP: 135.000 | FN: 26.000 |                                                                                        
Epoch [ 15/20 ] | Train Loss: 0.4309 | Val Loss: 0.8810 | Precision: 0.497 | Recall: 0.888 | F1: 0.637 | FP: 168.000 | FN: 21.000 |                                                                                        
Epoch [ 16/20 ] | Train Loss: 0.4022 | Val Loss: 0.9428 | Precision: 0.623 | Recall: 0.759 | F1: 0.684 | FP: 86.000 | FN: 45.000 |                                                                                         
Epoch [ 17/20 ] | Train Loss: 0.4245 | Val Loss: 0.8500 | Precision: 0.636 | Recall: 0.738 | F1: 0.683 | FP: 79.000 | FN: 49.000 |                                                                                         
Epoch [ 18/20 ] | Train Loss: 0.3656 | Val Loss: 1.0113 | Precision: 0.641 | Recall: 0.743 | F1: 0.688 | FP: 78.000 | FN: 48.000 |                                                                                         
Epoch [ 19/20 ] | Train Loss: 0.4100 | Val Loss: 1.0118 | Precision: 0.651 | Recall: 0.749 | F1: 0.697 | FP: 75.000 | FN: 47.000 |                                                                                         
Epoch [ 20/20 ] | Train Loss: 0.4015 | Val Loss: 0.7910 | Precision: 0.483 | Recall: 0.936 | F1: 0.638 | FP: 187.000 | FN: 12.000 |                                                                                        
Training Complete, Model saved

The metrics are now more stabilized:
    - Recall: very high (0.85-0.95)
    - Precision: Unstable (0.48-0.65)
    - F1: 0.68-0.70

"""

#------------------------------------------------------------------------------------------------------------------------------------------------------------

"""
Changes made after above results:

    - data/dataset.py - Data augmentation
    - train.py - BCE replaced with Focal Loss
"""


# class FocalLoss(nn.Module):
#     def __init__(self, alpha=0.25, gamma=2.0, reduction='mean'):
#         super().__init__()
#         self.alpha = alpha
#         self.gamma = gamma
#         self.reduction = reduction

#     def forward(self, logits, targets):
#         probs = torch.sigmoid(logits)
#         ce_loss = F.binary_cross_entropy_with_logits(logits, targets, reduction="none")
#         p_t = probs * targets + (1-probs) * (1 - targets)
#         loss = ce_loss * (self.alpha * (1 - p_t) ** self.gamma)
#         if self.reduction == "mean":
#             return loss.mean()
#         else:
#             return loss.sum()

# def compute_metrics(logits, labels, threshold):
#     probs = torch.sigmoid(logits)
#     preds = (probs >= threshold).long()

#     labels = labels.long()

#     TP = ((preds == 1) & (labels == 1)).sum().item()
#     FP = ((preds == 1) & (labels == 0)).sum().item()
#     FN = ((preds == 0) & (labels == 1)).sum().item()
#     TN = ((preds == 0) & (labels == 0)).sum().item()

#     precision = TP / (TP + FP + 1e-8)
#     recall    = TP / (TP + FN + 1e-8)
#     f1        = 2 * precision * recall / (precision + recall + 1e-8)

#     return {
#         "TP": TP,
#         "FP": FP,
#         "FN": FN,
#         "TN": TN,
#         "precision": precision,
#         "recall": recall,
#         "f1": f1,
#     }

# TRAIN_DIR = "dataset/trian"
# VAL_DIR = "dataset/val"

# NUM_FRAMES = 50
# BATCH_SIZE_FROZEN = 8
# BATCH_SIZE_UNFROZEN = 1
# EPOCHS = 20
# LR_BACKBONE = 1e-5
# LR_HEAD = 1e-4
# DEVICE = "cuda"

# def train_one_epoch(model, loader, optimizer, criterion, scaler):
#     model.train()
#     total_loss = 0.0

#     for videos, labels in tqdm(loader, desc="Training", leave=False):
#         videos = videos.to(DEVICE, non_blocking=True)
#         labels = labels.to(DEVICE, non_blocking=True)

#         optimizer.zero_grad(set_to_none=True)

#         #  AMP starts here
#         with torch.amp.autocast("cuda"):
#             logits = model(videos)
#             loss = criterion(logits, labels)

#         #  scaled backward pass
#         scaler.scale(loss).backward()
#         scaler.step(optimizer)
#         scaler.update()

#         total_loss += loss.item()

#     return total_loss / len(loader)

# @torch.no_grad()
# def validate(model, loader, criterion):
#     model.eval()
#     total_loss = 0.0
#     all_logits = []
#     all_labels = []

#     for videos, labels in tqdm(loader, desc="Validation", leave=False):
#         videos = videos.to(DEVICE)
#         labels = labels.to(DEVICE)

#         logits = model(videos)
#         loss = criterion(logits, labels)

#         total_loss += loss.item()
#         all_logits.append(logits)
#         all_labels.append(labels)

#     all_logits = torch.cat(all_logits)
#     all_labels = torch.cat(all_labels)

#     best_f1 = 0
#     best_threshold = 0.5
#     for t in torch.arange(0.2, 0.6, 0.01):
#         metrics = compute_metrics(all_logits, all_labels, threshold=t.item())
#         if metrics["f1"] > best_f1:
#             best_f1 = metrics["f1"]
#             best_threshold = t.item()

#     metrics = compute_metrics(all_logits, all_labels, threshold = best_threshold)
#     metrics['best_threshold'] = best_threshold

#     return total_loss / len(loader), metrics

# def main():

#     train_ds = VideoDataset("manifests/train.txt", NUM_FRAMES, augment=True)
#     val_ds = VideoDataset("manifests/val.txt", NUM_FRAMES, augment=False)

#     train_loader = DataLoader(
#         train_ds,
#         batch_size=BATCH_SIZE_FROZEN,
#         shuffle=True,
#         num_workers=4,
#         pin_memory=True
#     )

#     val_loader = DataLoader(
#         val_ds,
#         batch_size=BATCH_SIZE_UNFROZEN,
#         shuffle=False,
#         num_workers=4,
#         pin_memory=True
#     )

#     model = ShopliftingModel().to(DEVICE)

#     for param in model.spatial.parameters():
#         param.requires_grad = False

#     num_normal = sum(1 for _, l in train_ds.samples if l == 0)
#     num_shoplifting = sum(1 for _, l in train_ds.samples if l == 1)
#     pos_weight = torch.tensor(num_normal / (num_shoplifting + 1e-8)).to(DEVICE)


#     # criterion = BCEWithLogitsLoss(pos_weight=pos_weight)
#     criterion = FocalLoss(alpha=0.25, gamma=2.0)

#     optimizer = AdamW([
#         {"params": model.temporal.parameters(), "lr":1e-4},
#         {"params": model.classifier.parameters(), "lr":1e-4},

#     ])

#     scaler = torch.amp.GradScaler("cuda")

#     for epoch in range(EPOCHS):
#         train_loss = train_one_epoch(model, train_loader, optimizer, criterion, scaler)
#         val_loss, metrics = validate(model, val_loader, criterion)

#         print(
#             f"Epoch [ {epoch+1}/{EPOCHS} ] | "
#             f"Train Loss: {train_loss:.4f} | "
#             f"Val Loss: {val_loss:.4f} | "
#             f"Precision: {metrics['precision']:.3f} | "
#             f"Recall: {metrics['recall']:.3f} | "
#             f"F1: {metrics['f1']:.3f} | "
#             f"FP: {metrics['FP']:.3f} | "
#             f"FN: {metrics['FN']:.3f} | "
#             f"Best Thresh: {metrics['best_threshold']:.2f}"
#         )

#         if epoch == 4:
#             print("Unfreezing spatial backbone")
#             for g in optimizer.param_groups:
#                 g['lr'] *= 0.1
#             for name, param in model.spatial.backbone.named_parameters():
#                 if "blocks.4" not in name and "blocks.5" not in name:
#                     param.requires_grad = False

#             optimizer = AdamW([
#                 {"params": model.spatial.parameters(), "lr": 1e-5},
#                 {"params": model.temporal.parameters(), "lr": 1e-4},
#                 {"params": model.classifier.parameters(), "lr":1e-4},
#             ])

#     torch.save(model.state_dict(), "shoplifting_model_v6.pth")
#     print("Training Complete, Model saved")


# if __name__ == "__main__":
#     main()

"""
Results: 

Epoch [ 1/20 ] | Train Loss: 0.0361 | Val Loss: 0.0389 | Precision: 0.609 | Recall: 0.775 | F1: 0.682 | FP: 93.000 | FN: 42.000 | Best Thresh: 0.42 
Epoch [ 2/20 ] | Train Loss: 0.0321 | Val Loss: 0.0344 | Precision: 0.579 | Recall: 0.824 | F1: 0.680 | FP: 112.000 | FN: 33.000 | Best Thresh: 0.45 
Epoch [ 3/20 ] | Train Loss: 0.0313 | Val Loss: 0.0354 | Precision: 0.642 | Recall: 0.786 | F1: 0.707 | FP: 82.000 | FN: 40.000 | Best Thresh: 0.47 
Epoch [ 4/20 ] | Train Loss: 0.0315 | Val Loss: 0.0353 | Precision: 0.652 | Recall: 0.781 | F1: 0.710 | FP: 78.000 | FN: 41.000 | Best Thresh: 0.47 
Epoch [ 5/20 ] | Train Loss: 0.0290 | Val Loss: 0.0339 | Precision: 0.688 | Recall: 0.743 | F1: 0.715 | FP: 63.000 | FN: 48.000 | Best Thresh: 0.54 
Unfreezing spatial backbone 
Epoch [ 6/20 ] | Train Loss: 0.0293 | Val Loss: 0.0352 | Precision: 0.638 | Recall: 0.802 | F1: 0.711 | FP: 85.000 | FN: 37.000 | Best Thresh: 0.47 
Epoch [ 7/20 ] | Train Loss: 0.0296 | Val Loss: 0.0342 | Precision: 0.622 | Recall: 0.791 | F1: 0.696 | FP: 90.000 | FN: 39.000 | Best Thresh: 0.47 
Epoch [ 8/20 ] | Train Loss: 0.0289 | Val Loss: 0.0345 | Precision: 0.519 | Recall: 0.856 | F1: 0.646 | FP: 148.000 | FN: 27.000 | Best Thresh: 0.41 
Epoch [ 9/20 ] | Train Loss: 0.0273 | Val Loss: 0.0503 | Precision: 0.556 | Recall: 0.882 | F1: 0.682 | FP: 132.000 | FN: 22.000 | Best Thresh: 0.27 
Epoch [ 10/20 ] | Train Loss: 0.0270 | Val Loss: 0.0336 | Precision: 0.668 | Recall: 0.711 | F1: 0.689 | FP: 66.000 | FN: 54.000 | Best Thresh: 0.46 
Epoch [ 11/20 ] | Train Loss: 0.0253 | Val Loss: 0.0392 | Precision: 0.544 | Recall: 0.818 | F1: 0.654 | FP: 128.000 | FN: 34.000 | Best Thresh: 0.38 
Epoch [ 12/20 ] | Train Loss: 0.0264 | Val Loss: 0.0353 | Precision: 0.586 | Recall: 0.834 | F1: 0.689 | FP: 110.000 | FN: 31.000 | Best Thresh: 0.41 
Epoch [ 13/20 ] | Train Loss: 0.0282 | Val Loss: 0.0362 | Precision: 0.558 | Recall: 0.850 | F1: 0.674 | FP: 126.000 | FN: 28.000 | Best Thresh: 0.39 
Epoch [ 14/20 ] | Train Loss: 0.0244 | Val Loss: 0.0389 | Precision: 0.578 | Recall: 0.829 | F1: 0.681 | FP: 113.000 | FN: 32.000 | Best Thresh: 0.40 
Epoch [ 15/20 ] | Train Loss: 0.0213 | Val Loss: 0.0406 | Precision: 0.603 | Recall: 0.749 | F1: 0.668 | FP: 92.000 | FN: 47.000 | Best Thresh: 0.55 
Epoch [ 16/20 ] | Train Loss: 0.0238 | Val Loss: 0.0429 | Precision: 0.560 | Recall: 0.877 | F1: 0.683 | FP: 129.000 | FN: 23.000 | Best Thresh: 0.45 
Epoch [ 17/20 ] | Train Loss: 0.0218 | Val Loss: 0.0573 | Precision: 0.602 | Recall: 0.818 | F1: 0.694 | FP: 101.000 | FN: 34.000 | Best Thresh: 0.39 
Epoch [ 18/20 ] | Train Loss: 0.0229 | Val Loss: 0.0437 | Precision: 0.576 | Recall: 0.834 | F1: 0.681 | FP: 115.000 | FN: 31.000 | Best Thresh: 0.42 
Epoch [ 19/20 ] | Train Loss: 0.0231 | Val Loss: 0.0625 | Precision: 0.498 | Recall: 0.861 | F1: 0.631 | FP: 162.000 | FN: 26.000 | Best Thresh: 0.21 
Epoch [ 20/20 ] | Train Loss: 0.0229 | Val Loss: 0.0447 | Precision: 0.550 | Recall: 0.850 | F1: 0.668 | FP: 130.000 | FN: 28.000 | Best Thresh: 0.34 
Training Complete, Model saved

Here, Train-Val loss gap is smaller and Val loss stays in a tight band (0.033-0.045), this means less overfitting. 
F1 is more stable than ever (0.67-0.71).
Recall is 0.80-0.88 and FN is 20-40, means shoplifting classifications are more reliable. 

"""

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


class FocalLoss(nn.Module):
    def __init__(self, alpha=0.25, gamma=2.0, reduction='mean'):
        super().__init__()
        self.alpha = alpha
        self.gamma = gamma
        self.reduction = reduction

    def forward(self, logits, targets):
        probs = torch.sigmoid(logits)
        ce_loss = F.binary_cross_entropy_with_logits(logits, targets, reduction="none")
        p_t = probs * targets + (1-probs) * (1 - targets)
        loss = ce_loss * (self.alpha * (1 - p_t) ** self.gamma)
        if self.reduction == "mean":
            return loss.mean()
        else:
            return loss.sum()

def compute_metrics(logits, labels, threshold):
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

    best_f1 = 0
    best_threshold = 0.5
    for t in torch.arange(0.2, 0.6, 0.01):
        metrics = compute_metrics(all_logits, all_labels, threshold=t.item())
        if metrics["f1"] > best_f1:
            best_f1 = metrics["f1"]
            best_threshold = t.item()

    metrics = compute_metrics(all_logits, all_labels, threshold = best_threshold)
    metrics['best_threshold'] = best_threshold

    return total_loss / len(loader), metrics

def main():

    train_ds = VideoDataset("manifests/train.txt", NUM_FRAMES, augment=True)
    val_ds = VideoDataset("manifests/val.txt", NUM_FRAMES, augment=False)

    train_loader = DataLoader(
        train_ds,
        batch_size=BATCH_SIZE_FROZEN,
        shuffle=True,
        num_workers=0,
        pin_memory=True
    )

    val_loader = DataLoader(
        val_ds,
        batch_size=BATCH_SIZE_UNFROZEN,
        shuffle=False,
        num_workers=0,
        pin_memory=True
    )

    model = ShopliftingModel().to(DEVICE)

    for param in model.spatial.parameters():
        param.requires_grad = False

    num_normal = sum(1 for _, l in train_ds.samples if l == 0)
    num_shoplifting = sum(1 for _, l in train_ds.samples if l == 1)
    pos_weight = torch.tensor(num_normal / (num_shoplifting + 1e-8)).to(DEVICE)


    # criterion = BCEWithLogitsLoss(pos_weight=pos_weight)
    criterion = FocalLoss(alpha=0.25, gamma=2.0)

    optimizer = AdamW([
        {"params": model.temporal.parameters(), "lr":1e-4},
        {"params": model.classifier.parameters(), "lr":1e-4},

    ])

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
            f"Best Thresh: {metrics['best_threshold']:.2f}"
        )

        if epoch == 4:
            print("Unfreezing spatial backbone")
            for g in optimizer.param_groups:
                g['lr'] *= 0.1
            for name, param in model.spatial.backbone.named_parameters():
                if "blocks.4" not in name and "blocks.5" not in name:
                    param.requires_grad = False

            optimizer = AdamW([
                {"params": model.spatial.parameters(), "lr": 1e-5},
                {"params": model.temporal.parameters(), "lr": 1e-4},
                {"params": model.classifier.parameters(), "lr":1e-4},
            ])

    torch.save(model.state_dict(), "shoplifting_model_YOLO_v1.pth")
    print("Training Complete, Model saved")


if __name__ == "__main__":
    main()

"""
Epoch [ 1/20 ] | Train Loss: 0.0365 | Val Loss: 0.0329 | Precision: 0.759 | Recall: 0.690 | F1: 0.723 | FP: 41.000 | FN: 58.000 | Best Thresh: 0.51                                                                        
Epoch [ 2/20 ] | Train Loss: 0.0317 | Val Loss: 0.0377 | Precision: 0.713 | Recall: 0.717 | F1: 0.715 | FP: 54.000 | FN: 53.000 | Best Thresh: 0.51                                                                        
Epoch [ 3/20 ] | Train Loss: 0.0310 | Val Loss: 0.0373 | Precision: 0.663 | Recall: 0.684 | F1: 0.674 | FP: 65.000 | FN: 59.000 | Best Thresh: 0.51                                                                        
Epoch [ 4/20 ] | Train Loss: 0.0290 | Val Loss: 0.0441 | Precision: 0.660 | Recall: 0.759 | F1: 0.706 | FP: 73.000 | FN: 45.000 | Best Thresh: 0.38                                                                        
Epoch [ 5/20 ] | Train Loss: 0.0296 | Val Loss: 0.0359 | Precision: 0.641 | Recall: 0.791 | F1: 0.708 | FP: 83.000 | FN: 39.000 | Best Thresh: 0.47                                                                        
Unfreezing spatial backbone
Epoch [ 6/20 ] | Train Loss: 0.0275 | Val Loss: 0.0333 | Precision: 0.683 | Recall: 0.759 | F1: 0.719 | FP: 66.000 | FN: 45.000 | Best Thresh: 0.49                                                                        
Epoch [ 7/20 ] | Train Loss: 0.0236 | Val Loss: 0.0450 | Precision: 0.605 | Recall: 0.786 | F1: 0.684 | FP: 96.000 | FN: 40.000 | Best Thresh: 0.42                                                                        
Epoch [ 8/20 ] | Train Loss: 0.0257 | Val Loss: 0.0427 | Precision: 0.603 | Recall: 0.845 | F1: 0.704 | FP: 104.000 | FN: 29.000 | Best Thresh: 0.32                                                                       
Epoch [ 9/20 ] | Train Loss: 0.0286 | Val Loss: 0.0374 | Precision: 0.694 | Recall: 0.717 | F1: 0.705 | FP: 59.000 | FN: 53.000 | Best Thresh: 0.50                                                                        
Epoch [ 10/20 ] | Train Loss: 0.0240 | Val Loss: 0.0400 | Precision: 0.695 | Recall: 0.647 | F1: 0.670 | FP: 53.000 | FN: 66.000 | Best Thresh: 0.49                                                                       
Epoch [ 11/20 ] | Train Loss: 0.0259 | Val Loss: 0.0416 | Precision: 0.596 | Recall: 0.797 | F1: 0.682 | FP: 101.000 | FN: 38.000 | Best Thresh: 0.44                                                                      
Epoch [ 12/20 ] | Train Loss: 0.0226 | Val Loss: 0.0354 | Precision: 0.548 | Recall: 0.877 | F1: 0.675 | FP: 135.000 | FN: 23.000 | Best Thresh: 0.36                                                                      
Epoch [ 13/20 ] | Train Loss: 0.0209 | Val Loss: 0.0466 | Precision: 0.546 | Recall: 0.861 | F1: 0.668 | FP: 134.000 | FN: 26.000 | Best Thresh: 0.40                                                                      
Epoch [ 14/20 ] | Train Loss: 0.0223 | Val Loss: 0.0384 | Precision: 0.733 | Recall: 0.733 | F1: 0.733 | FP: 50.000 | FN: 50.000 | Best Thresh: 0.42                                                                       
Epoch [ 15/20 ] | Train Loss: 0.0190 | Val Loss: 0.0505 | Precision: 0.637 | Recall: 0.770 | F1: 0.697 | FP: 82.000 | FN: 43.000 | Best Thresh: 0.56                                                                       
Epoch [ 16/20 ] | Train Loss: 0.0194 | Val Loss: 0.0485 | Precision: 0.631 | Recall: 0.668 | F1: 0.649 | FP: 73.000 | FN: 62.000 | Best Thresh: 0.47                                                                       
Epoch [ 17/20 ] | Train Loss: 0.0202 | Val Loss: 0.0474 | Precision: 0.653 | Recall: 0.775 | F1: 0.709 | FP: 77.000 | FN: 42.000 | Best Thresh: 0.40                                                                       
Epoch [ 18/20 ] | Train Loss: 0.0164 | Val Loss: 0.0588 | Precision: 0.667 | Recall: 0.791 | F1: 0.724 | FP: 74.000 | FN: 39.000 | Best Thresh: 0.39                                                                       
Epoch [ 19/20 ] | Train Loss: 0.0178 | Val Loss: 0.0515 | Precision: 0.706 | Recall: 0.759 | F1: 0.732 | FP: 59.000 | FN: 45.000 | Best Thresh: 0.49                                                                       
Epoch [ 20/20 ] | Train Loss: 0.0158 | Val Loss: 0.0537 | Precision: 0.613 | Recall: 0.781 | F1: 0.687 | FP: 92.000 | FN: 41.000 | Best Thresh: 0.34                                                                       
Training Complete, Model saved
"""
