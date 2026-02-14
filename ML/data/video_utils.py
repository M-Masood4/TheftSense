import cv2
import torch
import numpy as np 

def load_video_frames(video_path, num_frames = 50, size = 224):

    """
    Load and uniformally sample frames from a video clip.

    This function reads a video file, uniformally samples a fixed number
    of frames accross its entire duration, applies spatial preprocessing, 
    and returns a tensor suitable for deep learning models. 

    Parameters:

        video_path : str
            Path to the input video file.
        num_frames : int, optional
            Number of frames to sample from the video (default: 50).
            Frames are samples uniformaly across the clip duration.
        size : int, optional 
            Spatial resolution (height, and width) to resize frames to
            (default: 224).

    Returns:
        torch.Tensor
            A tensor of shape (T,C,H,W) where:
                T = num_frames
                C = 3 (RGB channels)
                H = Height
                W = Width
    
    Notes:
        - Uniform temporal sampling ensures coverage of the full clip and
          avoids redundancy from consecutive frames.
        - Frames are normalized to [0,1].
        - Output is compatible with CNN backbones such as EfficientNetV2.

    """
    
    cap = cv2.VideoCapture(video_path) # opens the video file, gives random access to frames, faster and more stable than frame-by-frme reading.
    frames = []

    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT)) # videos may be 25,30, 45, 60 fps and we don't want to hard-code that, sampling should be done evenly accross the clip.
    indices = np.linspace(0, total_frames - 1, num_frames).astype(int) # Selects num_frames indices, spread evenly across from start to end, covers whole action (before - during - after)

    for idx in indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, idx) # Jump directly to specific frames, avoides decoding unecessary ones. 
        ret, frame = cap.read()
        if not ret:
            break

        frame = cv2.cvtColOr(frame, cv2.COLOR_BGR2RGB) # OpenCV loads images as BGR, PyTorch/pretrained models expect RGB 
        frame = cv2.resize(frame, (size, size)) # fixed size for batch processing 
        frames.append(frame)

    cap.release()

    frames = np.stack(frames) # stack and normalize frames. CNNs expect pixel values in [0,1]
    frames = frames / 255.0

    frames = torch.tensor(frames).permute(0, 3, 1, 2) # convert to PyTorch tensor (T,H,W,C) -> [T,C,H,W]

    return frames