import os
import matplotlib.pyplot as plt 

DATASET_ROOT = "dataset/train"

def plot_class_distribution():

    """
    Class Distribution Analysis

    This script analysis the distribution of training samples
    across classes (Normal vs Shoplifting).

    Purpose
        - Identify class imbalance before model training.
        - Prevent misleading accuracy caused by skewed data.
        - Inform later decisions such as loss weighting or sampling

    Method
        - Each video clip is treated as one independent sample.
        - The number of files per class directory is counted.
        - Results are visualized using a bar chart.

    Assumptions
        - Dataset is already split into train/val/test
        - Folder structure:
            dataset/train/{normal, shoplifting}

    Notes
        - Only the training split is analyzed.
        - Validation and test splits are intentionally excluded.
        - This analysis does not modify any data.
    """

    classes = ["normal", "shoplifting"]
    counts = []

    for cls in classes:
        cls_path = os.path.join(DATASET_ROOT, cls)
        counts.append(len(os.listdir(cls_path)))

    plt.bar(classes, counts)
    plt.title("Class Distribution (Train Set)")
    plt.ylabel("Number of clips")
    plt.show()

if __name__ == "__main__":
    plot_class_distribution()