import os
import torch
import cv2
import numpy as np
import boto3
from ultralytics import YOLO
from models.model import ShopliftingModel

"""
This script implements a complete edge based video inference pipeline for
shoplifting detection. It integrates spatial object detection (YOLOV8n) with
a Temporal Transformer and Spatial Encoder based behavior classification model.

The pipeline performs the following steps:

    1. Downloads an input video from AWS S3
    2. Performs frame-wise object detection using YOLOV8
    3. Extracts cropped person regions
    4. Builds a temporal sequence of frames
    5. Performs behavior classification using a trained Transformer + Spatial Encoder model
    6. Annotates the video with bounding boxes and predictions
    7. Uploads the processed video back to AWS S3.

This script is designed for edge development on Raspberry Pi 5 and operates in 
batch-processing mode. 

Inputs

    Required: 
        - AWS S3 Bucket Name
        - S3 object key (input video path)
        - YOLOV8 weights file
        - Model .pth file

Outputs

    Primary Output:
        - Annotated MP4 video stored in S3

    Embedded in Output:
        - Bounding boxes (YOLO)
        - Behavior classificaion label
        - COnfidence Score
"""

DEVICE = torch.device("cpu")
THRESHOLD = 0.42

S3_BUCKET = "" # Bucket name 
S3_INPUT_KEY = "" # Input path
S3_OUTPUT_KEY = "" # Output Path

LOCAL_INPUT = "" # input file name
LOCAL_OUTPUT = "" # output file name

s3 = boto3.client("s3")

s3.download_file(S3_BUCKET, S3_INPUT_KEY, LOCAL_INPUT)

yolo = YOLO("yolov8n.pt")
model = ShopliftingModel()
model.load_state_dict(torch.load("shoplifitng_model_YOLO_v1.pth", map_location=DEVICE))
model.to(DEVICE)
model.eval()

cap = cv2.VideoCapture(LOCAL_INPUT)

fourcc = cv2.VideoWriter_fourcc(*'mp4v')
fps = cap.get(cv2.CAP_PROP_FPS)
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

out = cv2.VideoWriter(LOCAL_OUTPUT, fourcc, fps, (width, height))
frames_for_model = []

print("Running inference....")

while True:
    ret, frame = cap.read()
    if not ret:
        break

    results = yolo(frame, verbose=False)[0]
    annotated_frame = results.plot()

    for box in results.boxes:
        if int(box.cls) == 0:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            cropped = frame[y1:y2, x1:x2]
            cropped = cv2.resize(cropped, (224, 224))
            frames_for_model.append(cropped)

            break

    out.write(annotated_frame)

cap.release()
out.release()

print("Running temporal classification.....")

prob = 0.0

if len(frames_for_model) > 0:
    frames = np.array(frames_for_model)
    frames = frames / 255.0
    frames = torch.tensor(frames).permute(0,3,1,2).float()
    frames = frames.unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        output = model(frames)
        prob = torch.sigmoid(output).item()

print("Shoplifting Probability: ", prob)

cap = cv2.VideoCapture(LOCAL_OUTPUT)
final_output = "final_output.mp4"
final_writer = cv2.VideoWrier(final_output, fourcc, fps, (width, height))

while True:
    ret, frame = cap.read()
    if not ret:
        break

    label_text = f"Shoplifting: {prob*100:.1f}%"
    normal_text = f"Normal: {(1-prob)*100:.1f}%"

    color = {0, 0, 255} if prob > THRESHOLD else (0, 255, 0)

    cv2.rectangle(frame, (10, 10), (380, 90), color, -1)
    cv2.putText(frame, label_text, (20,45),
                cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0,0,0), 2)
    cv2.putText(frame, normal_text, (20,75),
                cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0,0,0), 2)
    
    final_writer.write(frame)

cap.release()
final_writer.release()

print("Uploading labeled video back to S3...")
s3.upload_file(final_output, S3_BUCKET, S3_OUTPUT_KEY)
print("Done")
