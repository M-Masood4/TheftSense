import os
import cv2
import torch
import numpy as np
import matplotlib
matplotlib.use("Agg")  # headless-friendly backend
import matplotlib.pyplot as plt
from data.s3_utils import download_if_needed

NUM_SAMPLES = 20  # number of videos per class to analyze

def motion_intensity(video_path, max_frames=50):
    """
    Computes average frame-to-frame pixel differences.
    """
    cap = cv2.VideoCapture(video_path)
    prev = None
    diffs = []

    count = 0
    while count < max_frames:
        ret, frame = cap.read()
        if not ret:
            break
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        if prev is not None:
            diff = np.mean(np.abs(gray.astype(float) - prev.astype(float)))
            diffs.append(diff)

        prev = gray
        count += 1

    cap.release()
    return np.mean(diffs) if diffs else 0

def sample_motion_distribution_from_manifest(manifest_path, num_samples=20, target_label=0):
    """
    Samples motion intensity from videos listed in a manifest.

    Args:
        manifest_path (str): path to manifest file (S3 URIs + labels)
        num_samples (int): number of videos to sample
        target_label (int): 0 = normal, 1 = shoplifting
    """
    with open(manifest_path, "r") as f:
        samples = [line.strip().split() for line in f if int(line.strip().split()[1]) == target_label]

    if len(samples) == 0:
        raise ValueError(f"No samples with label {target_label} in manifest {manifest_path}")

    # Randomly select num_samples
    import random
    selected = random.sample(samples, min(num_samples, len(samples)))

    motion_values = []
    for s3_uri, _ in selected:
        local_path = download_if_needed(s3_uri)
        motion_values.append(motion_intensity(local_path))

    return motion_values

if __name__ == "__main__":
    # Paths to manifests
    VAL_MANIFEST = "manifests/val.txt"

    normal_motion = sample_motion_distribution_from_manifest(VAL_MANIFEST, NUM_SAMPLES, target_label=0)
    shoplifting_motion = sample_motion_distribution_from_manifest(VAL_MANIFEST, NUM_SAMPLES, target_label=1)

    plt.hist(normal_motion, alpha=0.6, label="Normal")
    plt.hist(shoplifting_motion, alpha=0.6, label="Shoplifting")
    plt.legend()
    plt.title("Motion Intensity Distribution")
    plt.xlabel("Average Frame-to-Frame Pixel Difference")
    plt.ylabel("Number of Clips")
    plt.savefig("motion_intensity_distribution.png")  # headless-safe
    print("Motion intensity histogram saved as motion_intensity_distribution.png")
