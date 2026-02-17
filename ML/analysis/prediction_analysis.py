import torch
import matplotlib
from models.model import ShopliftingModel
from data.dataset import VideoDataset 
from torch.utils.data import DataLoader
from dotenv import load_dotenv
matplotlib.use("Agg")  # use non-interactive backend
import matplotlib.pyplot as plt



load_dotenv("keys.env")
"""
This module analyzes the confidence of model predictions
on the validation dataset.

Purpose
    - Understand how confident the model is in its predictions.
    - Identify overconfidence or uncertainity in classification.
    - Support threshold tuning decisions.
    - Explain false positives and false negatives.

Method
    - Run inference on the validation set
    - Convert logits to probabilities using sigmoid 
    - Separate predictions by ground-truth class
    - Visualize probability distributions using histograms

Interpretation
    - Well-separated distributions indicate strong discriminative ability.
    - Ovelap near the decision threshold indicates ambiguity.
    - CLustering near 0.5 suggests model uncertainity.

Notes
    - Analysis is performed only on validation data.
    - Test data is intentionally excluded.
    - No training parameters are modified. 

Changes
    - Smoothed distributions used after results from shoplifting_model_v3.pth.
"""

import numpy as np

def temporal_smooth(probs, window=5):
    smoothed = []
    for i in range(len(probs)):
        start = max(0, i - window + 1)
        smoothed.append(np.mean(probs[start:i+1]))
    return np.array(smoothed)


DEVICE = "cuda"
MODEL_PATH = "shoplifting_model_YOLO_v1.pth"
DATA_DIR = "manifests/val.txt"

model = ShopliftingModel().to(DEVICE)
model.load_state_dict(torch.load(MODEL_PATH))
model.eval()

dataset = VideoDataset(DATA_DIR, num_frames=50)
loader = DataLoader(dataset, batch_size=4, shuffle=False)

all_probs = []
all_labels = []

with torch.no_grad():
    for videos, labels in loader:
        videos = videos.to(DEVICE)
        logits = model(videos)
        probs = torch.sigmoid(logits)

        all_probs.extend(probs.cpu().numpy())
        all_labels.extend(labels.numpy())

smoothed_probs = temporal_smooth(all_probs, window=5)

plt.hist(
    [p for p, l in zip(smoothed_probs, all_labels) if l == 0],
    alpha=0.6,
    label="Normal",
)

plt.hist(
    [p for p, l in zip(smoothed_probs, all_labels) if l == 1],
    alpha=0.6,
    label="Shoplifting",
)

plt.axvline(0.35, linestyle="--", color="Black")
plt.legend()
plt.title("Prediction Confidence Distribution")
plt.savefig("prediction_confidence_YOLO_v1.png")  # save instead of plt.show()

# cd ~/Desktop/CS3305
# python3 -m analysis.prediction_analysis