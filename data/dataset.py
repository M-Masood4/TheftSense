import os
import torch
import cv2
from torch.utils.data import Dataset
from data.s3_utils import download_if_needed

class VideoDataset(Dataset):

    """
    A PyTorch dataset for loading fixed-length video clips
    for binary shoplifting classification. 

    Each video clip is assumed to epresnt a single training example.

    Parameters:

        root_dir : str
            Path to the dataset split (train / val / test).

        num_frames : int, optional (default=50)
            Number of frames uniformly sampled from each clip.

    Returns:

    frames : torch.Tensor
        Tensor of shape (T,C,H,W) where:
            - T = num_frames
            - C = 3 (RGB)
            - H = Height
            - W = Width

    label : torch.Tensor
        Scalar tensor:
            - 0.0 -> normal
            - 1.0 -> shoplifting

    Notes
        - Videos are loaded on demand
        - No data is cached in memory 
        - This class assumes no data leakage, all clips in root_dir belong to the same split. 

    Directory Structure assumed:

    root_dir/
        normal/
            clip_001.mp4
            ...
        shoplifting/
            clip_101.mp4
            ...

    """

    def __init__(self, manifest_path, num_frames = 50):

        self.samples = []
        self.num_frames = num_frames

        with open(manifest_path, "r") as f:
            for line in f:
                s3_uri, label = line.strip().split()
                self.samples.append((s3_uri, int(label)))

    def __len__(self):
        return len(self.samples)
    
    def __getitem__(self, idx):
        
        s3_uri, label = self.samples[idx]
        local_video = download_if_needed(s3_uri)
        frames = self._load_video(local_video)

        return frames, torch.tensor(label, dtype=torch.float32)
    
    def _load_video(self, path):
        cap = cv2.VideoCapture(path)
        frames = []

        total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        step = max(total // self.num_frames, 1)

        count = 0
        while len(frames) < self.num_frames:
            ret, frame = cap.read()
            if not ret:
                break

            if count % step == 0:
                frame = cv2.resize(frame, (224,224))
                frame = frame[:, :, ::-1]
                frame = torch.from_numpy(frame.copy()).permute(2,0,1).float() / 255.0
                frames.append(frame)

            count += 1

        cap.release()

        while len(frames) < self.num_frames:
            frames.append(frames[-1].clone())

        return torch.stack(frames)