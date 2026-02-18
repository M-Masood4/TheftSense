import torch
import numpy as np
from torch.utils.data import DataLoader
from sklearn.metrics import precision_score, recall_score, f1_score, confusion_matrix, classification_report

from data.dataset import VideoDataset
from models.model import ShopliftingModel

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
BATCH_SIZE = 8
TEST_DIR = "manifests/test.txt"
MODEL_PATH = "shoplifting_model_YOLO_v1.pth"

THRESHOLD = 0.42

model = ShopliftingModel()
model.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE))
model.to(DEVICE)
model.eval()

print("Model loaded successfully.")

test_dataset = VideoDataset(TEST_DIR, augment=False)
test_loader = DataLoader(test_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=0, pin_memory=True)
print("Test dataset loaded. Total samples: ", len(test_dataset))

all_preds = []
all_labels = []
all_probs = []

with torch.no_grad():
    for videos, labels in test_loader:
        videos = videos.to(DEVICE)
        labels = labels.to(DEVICE)
        outputs = model(videos)

        probs = torch.sigmoid(outputs)

        preds = (probs > THRESHOLD).float()

        all_preds.extend(preds.cpu().numpy().flatten())
        all_labels.extend(labels.cpu().numpy().flatten())
        all_probs.extend(probs.cpu().numpy().flatten())

all_preds = np.array(all_preds).astype(int)
all_labels = np.array(all_labels).astype(int)

precision = precision_score(all_labels, all_preds)
recall = recall_score(all_labels, all_preds)
f1 = f1_score(all_labels, all_preds)
cm = confusion_matrix(all_labels, all_preds)


print("Test Results: ")
print(f"Precision: {precision:.4f}")
print(f"Recall: {recall:.4f}")
print(f"F1 Score: {f1:.4f}")
print("\n Confusion Matrix: ")
print(cm)

print("\n Classification Report: ")
print(classification_report(all_labels, all_preds, target_names=["Normal", "Shoplifting"]))


"""
Results: 

Model loaded successfully.
Test dataset loaded. Total samples:  474
Test Results: 
Precision: 0.6557
Recall: 0.7354
F1 Score: 0.6933

 Confusion Matrix: 
[[212  73]
 [ 50 139]]

 Classification Report: 
              precision    recall  f1-score   support

      Normal       0.81      0.74      0.78       285
 Shoplifting       0.66      0.74      0.69       189

    accuracy                           0.74       474
   macro avg       0.73      0.74      0.73       474
weighted avg       0.75      0.74      0.74       474

"""