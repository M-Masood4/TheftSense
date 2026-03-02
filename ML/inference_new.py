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
video_keys = [obj['Key'] for obj in resp.get('Contents', []) if obj['Key'].lower().endswith('.mp4')]
print(f"Found {len(video_keys)} videos to process")

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

        label_width = int(width * 0.2)
        label_height = int(height * 0.08)
        font_scale = label_height / 50
        thickness = max(1, label_height // 20)

        cv2.rectangle(frame, (10,10), (10 + label_width, 10 + label_width), color, -1)
        cv2.putText(frame, label_text, (20, 10 + int(label_height*0.4)), cv2.FONT_HERSHEY_SIMPLEX, font_scale, (0,0,0), thickness)
        cv2.putText(frame, normal_text, (20, 10 + int(label_height*0.8)), cv2.FONT_HERSHEY_SIMPLEX, font_scale, (0,0,0), thickness)
    
        label_text = f"Shoplifting: {prob*100:.1f}%"
        normal_text = f"Normal: {(1-prob)*100:.1f}%"
        color = (0,0,255) if prob > THRESHOLD else (0,255,0)
        cv2.rectangle(frame, (5,5), (220,50), color, -1)
        cv2.putText(frame, label_text, (10,23), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0,0,0), 2)
        cv2.putText(frame, normal_text, (10,40), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0,0,0), 2)

        final_writer.write(frame)

    cap.release()
    final_writer.release()

    """
    Uploads th final annotated vidoe to the OUTPUT_BUCKET under 'videos/' prefix, 
    appending '_labeled' to the filename. 
    """

    output_key = f"{OUTPUT_BUCKET}/{filename.replace('.mp4', '_labeled.mp4')}"
    s3.upload_file(local_final, OUTPUT_BUCKET, f"videos/{filename.replace('.mp4', '_labeled.mp4')}")
    print(f"Uploaded annotated video to S3: videos/{filename.replace('.mp4', '_labeled.mp4')}")
        

