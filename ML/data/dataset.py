import os
import torch
import cv2
from torch.utils.data import Dataset
from data.s3_utils import download_if_needed
import torchvision.transforms as T
import random
from ultralytics import YOLO

# class VideoDataset(Dataset):

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

#     def __init__(self, manifest_path, num_frames = 50):

#         self.samples = []
#         self.num_frames = num_frames

#         with open(manifest_path, "r") as f:
#             for line in f:
#                 s3_uri, label = line.strip().split()
#                 self.samples.append((s3_uri, int(label)))

#     def __len__(self):
#         return len(self.samples)
    
#     def __getitem__(self, idx):
        
#         s3_uri, label = self.samples[idx]
#         local_video = download_if_needed(s3_uri)
#         frames = self._load_video(local_video)

#         return frames, torch.tensor(label, dtype=torch.float32)
    
#     def _load_video(self, path):
#         cap = cv2.VideoCapture(path)
#         frames = []

#         total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
#         step = max(total // self.num_frames, 1)

#         count = 0
#         while len(frames) < self.num_frames:
#             ret, frame = cap.read()
#             if not ret:
#                 break

#             if count % step == 0:
#                 frame = cv2.resize(frame, (224,224))
#                 frame = frame[:, :, ::-1]
#                 frame = torch.from_numpy(frame.copy()).permute(2,0,1).float() / 255.0
#                 frames.append(frame)

#             count += 1

#         cap.release()

#         while len(frames) < self.num_frames:
#             frames.append(frames[-1].clone())

#         return torch.stack(frames)

#---------------------------------------------------------------------------------------------------------------------------------------
    

# class VideoDataset(Dataset):

#     """
#     Changes: 
#         - Data augmentation introduced after results from shoplifting_model_v4.pth
#     """

#     def __init__(self, manifest_path, num_frames = 50, augment=False):

#         self.samples = []
#         self.num_frames = num_frames
#         self.augment = augment

#         self.spatial_transform = T.Compose([
#             T.ToPILImage(),
#             T.RandomHorizontalFlip(p=0.5),
#             T.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
#             T.Resize((224,224)),
#             T.ToTensor(),
#         ])

#         with open(manifest_path, "r") as f:
#             for line in f:
#                 s3_uri, label = line.strip().split()
#                 self.samples.append((s3_uri, int(label)))

#     def __len__(self):
#         return len(self.samples)
    
#     def __getitem__(self, idx):
        
#         s3_uri, label = self.samples[idx]
#         local_video = download_if_needed(s3_uri)
#         frames = self._load_video(local_video)

#         if self.augment:
#             frames = self._temporal_augment(frames)
#             frames = torch.stack([self.spatial_transform(f.permute(1,2,0).numpy()) for f in frames])

#         return frames, torch.tensor(label, dtype=torch.float32)
    
#     def _load_video(self, path):
#         cap = cv2.VideoCapture(path)
#         frames = []

#         total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
#         step = max(total // self.num_frames, 1)

#         count = 0
#         while len(frames) < self.num_frames:
#             ret, frame = cap.read()
#             if not ret:
#                 break

#             if count % step == 0:
#                 frame = cv2.resize(frame, (224,224))
#                 frame = frame[:, :, ::-1]
#                 frame = torch.from_numpy(frame.copy()).permute(2,0,1).float() / 255.0
#                 frames.append(frame)

#             count += 1

#         cap.release()

#         while len(frames) < self.num_frames:
#             frames.append(frames[-1].clone())

#         return torch.stack(frames)
    
#     def _temporal_augment(self, frames):
#         skip_ratio = random.uniform(0, 0.1)
#         num_skip = int(len(frames) * skip_ratio)
#         if num_skip > 0:
#             idxs = sorted(random.sample(range(len(frames)), num_skip))
#             frames = [f for i, f in enumerate(frames) if i not in idxs]

#         window_size = max(2, len(frames) // 10)

#         for i in range(0, len(frames)-window_size, window_size*2):
#             if random.random() < 0.5:
#                 frames[i:i+window_size], frames[i+window_size:i+2*window_size] = \
#                     frames[i+window_size:i+2*window_size], frames[i:i+window_size]
                
#         while len(frames) < self.num_frames:
#             frames.append(frames[-1].clone())

#         step = max(1, len(frames) // self.num_frames)
#         frames = frames[::step][:self.num_frames]
#         return frames

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

class VideoDataset(Dataset):

    """
    Changes: 
        - YOLO Model, helper function and configuration added. 
    """

    def crop_person(self, frame):
        results = self.yolo_model(frame, verbose=False)[0]

        boxes = results.boxes

        if boxes is None or len(boxes) == 0:
            return frame
        
        for box in boxes:
            if int(box.cls[0]) == 0:
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                h, w, _ = frame.shape

                x1 = max(0, x1)
                y1 = max(0, y1)
                x2 = min(w, x2)
                y2 = min(h, y2)

                return frame[y1:y2, x1:x2]
            
        return frame


    def __init__(self, manifest_path, num_frames = 50, augment=False):

        self.samples = []
        self.num_frames = num_frames
        self.augment = augment
        self.yolo_model = YOLO("yolov8n.pt")
        self.yolo_model.to("cuda" if torch.cuda.is_available() else "cpu")

        self.spatial_transform = T.Compose([
            T.ToPILImage(),
            T.RandomHorizontalFlip(p=0.5),
            T.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
            T.Resize((224,224)),
            T.ToTensor(),
        ])

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

        if self.augment:
            frames = self._temporal_augment(frames)
            frames = torch.stack([self.spatial_transform(f.permute(1,2,0).numpy()) for f in frames])

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

            # if count % step == 0:
            #     frame = cv2.resize(frame, (224,224))
            #     frame = frame[:, :, ::-1]
            #     frame = torch.from_numpy(frame.copy()).permute(2,0,1).float() / 255.0
            #     frames.append(frame)

            # count += 1

            if count % step == 0:

                cropped = self.crop_person(frame)
                if cropped is None or cropped.size == 0:
                    cropped = frame

                cropped = cv2.resize(cropped, (224,224))

                cropped = cropped[:, :, ::-1]

                cropped = torch.from_numpy(cropped.copy()).permute(2,0,1).float() / 255.0

                frames.append(cropped)

            count += 1

        cap.release()

        while len(frames) < self.num_frames:
            frames.append(frames[-1].clone())

        return torch.stack(frames)
    
    def _temporal_augment(self, frames):
        skip_ratio = random.uniform(0, 0.1)
        num_skip = int(len(frames) * skip_ratio)
        if num_skip > 0:
            idxs = sorted(random.sample(range(len(frames)), num_skip))
            frames = [f for i, f in enumerate(frames) if i not in idxs]

        window_size = max(2, len(frames) // 10)

        for i in range(0, len(frames)-window_size, window_size*2):
            if random.random() < 0.5:
                frames[i:i+window_size], frames[i+window_size:i+2*window_size] = \
                    frames[i+window_size:i+2*window_size], frames[i:i+window_size]
                
        while len(frames) < self.num_frames:
            frames.append(frames[-1].clone())

        step = max(1, len(frames) // self.num_frames)
        frames = frames[::step][:self.num_frames]
        return frames

    
