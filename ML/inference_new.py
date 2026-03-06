import os
import torch
import cv2
import numpy as np
import boto3
from ultralytics import YOLO
from models.model import ShopliftingModel

DEVICE = torch.device("cpu")
NUM_FRAMES = 50
THRESHOLD = 0.42

INPUT_BUCKET = "t13-users-videos"
OUTPUT_BUCKET = "t13-marked-videos"
INPUT_PREFIX = "Jack/"

YOLO_WEIGHTS = "yolov8n.pt"
MODEL_WEIGHTS = "shoplifting_model_YOLO_v1.pth"

os.makedirs("tmp", exist_ok=True)

s3 = boto3.client("s3")
yolo = YOLO(YOLO_WEIGHTS)

"""
YOLO object detection model (Ultralytics YOLOv8n) for detecting persons in video frames.
"""

model = ShopliftingModel()
model.load_state_dict(torch.load(MODEL_WEIGHTS, map_location=DEVICE))
model.to(DEVICE)
model.eval()

"""
Temporal shoplifting classification model.

Input: tensor of shape (1, NUM_FRAMES, 3, 224, 224)
Output: scaler probability (after sigmoid) of shoplifting
"""

resp = s3.list_objects_v2(Bucket = INPUT_BUCKET, Prefix = INPUT_PREFIX)
videos = [
    obj for obj in resp.get("Contents", [])
    if obj["Key"].lower().endswith(".mp4")
]

if not videos:
    print("No videos found in bucket.")
    exit()

videos.sort(key=lambda x: x["LastModified"], reverse=True)
latest_video = videos[0]["Key"]
print(f"Latest video detected: {latest_video}")

key = latest_video
filename = os.path.basename(key)

local_input = f"tmp/{filename}"
local_intermediate = f"tmp/intermediate_{filename}"
local_final = f"tmp/final_{filename}"

print(f"\nProcessing: {key}")
s3.download_file(INPUT_BUCKET, key, local_input)


for key in video_keys:
    filename = os.path.basename(key)
    local_input = f"tmp/{filename}"
    local_intermediate = f"tmp/intermediate_{filename}"
    local_final = f"tmp/final_{filename}"

    print(f"\nProcessing: {key}")
    s3.download_file(INPUT_BUCKET, key, local_input)

    """
    Reads input video frame by frame, performs YOLO detection, and:
        1. Saves an annotated version (intermediate video)
        2. Crops first detected person in each frame, resizes to 224x224,
           accumulates frames for temporal classification
    """

    cap = cv2.VideoCapture(local_input)
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    fps = cap.get(cv2.CAP_PROP_FPS) or 25
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    intermediate_writer = cv2.VideoWriter(local_intermediate, fourcc, fps, (width, height))
    frames_for_model = []

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        results = yolo(frame, verbose=False)[0]
        annotated_frame = results.plot()

        for box in results.boxes:
            if int(box.cls[0]) == 0:
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                h, w, _ = frame.shape
                x1, y1 = max(0, x1), max(0, y1)
                x2, y2 = min(w, x2), min(h, y2)
                cropped = frame[y1:y2, x1:x2]
                if cropped.size != 0:
                    cropped = cv2.resize(cropped, (224,224))
                    frames_for_model.append(cropped)
                break
        
        intermediate_writer.write(annotated_frame)

    cap.release()
    intermediate_writer.release()

    """
    Uses the pre-trained ShopliftingModel to predict the probability that the video contains
    shoplifting, based on NUM_FRAMES extracted from YOLO-cropped person frames.

    Steps:
        - Normalize frames to exactly NUM_FRAMES (pad/reduce as needed)
        - Convert frames to torch tensor (N, C, H, W) format
        - Run model and apply sigmoid to obtain probability
    """

    prob = 0.0

    if frames_for_model:

        if len(frames_for_model) > NUM_FRAMES:
            step = len(frames_for_model) // NUM_FRAMES
            frames_for_model = frames_for_model[::step][:NUM_FRAMES]
        while len(frames_for_model) < NUM_FRAMES:
            frames_for_model.append(frames_for_model[-1])

        frames = np.array(frames_for_model) / 255.0
        frames = torch.tensor(frames).permute(0,3,1,2).float().unsqueeze(0).to(DEVICE)

        with torch.no_grad():
            output = model(frames)
            prob = torch.sigmoid(output).item()

    print(f"Shoplifting Probability: {prob:.4f}")

    """
    Overlays shoplifting/normal probability labels on the video.
    The label size is adaptive to video resolution to avoid blocking too much of the frame.
    """

    cap = cv2.VideoCapture(local_intermediate)
    final_writer = cv2.VideoWriter(local_final, fourcc, fps, (width, height))

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        font_scale = 0.55
        font = cv2.FONT_HERSHEY_SIMPLEX
        thickness = 1
        
        label_text = f"Shoplifting: {prob*100:.1f}%"
        normal_text = f"Normal: {(1-prob)*100:.1f}%"
        
        (size1, _) = cv2.getTextSize(label_text, font, font_scale, thickness)
        (size2, _) = cv2.getTextSize(normal_text, font, font_scale, thickness)
        
        text_w = max(size1[0], size2[0])
        text_h = size1[1] + size2[1]
        
        padding = 8
        box_w = text_w + padding * 2
        box_h = text_h + padding * 3
        
        x1 = frame.shape[1] - box_w - 15
        y1 = 15
        x2 = x1 + box_w
        y2 = y1 + box_h
        
        color = (0, 0, 255) if prob > THRESHOLD else (0, 150, 0)
        
        overlay = frame.copy()
        cv2.rectangle(overlay, (x1,y1), (x2, y2), color, -1)
        alpha = 0.6
        frame = cv2.addWeighted(overlay, alpha, frame, 1-alpha, 0)
        
        cv2.putText(frame, label_text, (x1+padding, y1+padding+size1[1]), font, font_scale, (255, 255, 255), thickness)
        
        cv2.putText(frame, normal_text, (x1 + padding, y1 + padding + size1[1] + size2[1] + 5), font, font_scale, (255, 255, 255), thickness )
        
        
        
        
        final_writer.write(frame)

    cap.release()
    final_writer.release()

    """
    Uploads th final annotated vidoe to the OUTPUT_BUCKET under 'videos/' prefix, 
    appending '_labeled' to the filename. 
    """
    os.system(f"ffmpeg -y -i {local_final} -c:v libx264 -preset fast -crf 23 {local_final}_fixed.mp4")
    UPLOAD_FILE = f"{local_final}_fixed.mp4"
    output_key = f"{OUTPUT_BUCKET}/{filename.replace('.mp4', '_labeled.mp4')}"
    s3.upload_file(UPLOAD_FILE, OUTPUT_BUCKET, f"videos/{filename.replace('.mp4', '_labeled.mp4')}", ExtraArgs = {"ContentType": "video/mp4"})
    print(f"Uploaded annotated video to S3: videos/{filename.replace('.mp4', '_labeled.mp4')}")
        

