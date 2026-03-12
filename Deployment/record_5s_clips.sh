#!/bin/bash

# Settings

FOLDER="Jack"

BUCKET="t13-users-videos"   # ← CHANGE TO YOUR BUCKET NAME

mkdir -p "$FOLDER"

echo "Starting 5s MP4 recording + S3 upload. Ctrl+C to stop."

while true; do

  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

  OUTPUT="$FOLDER/clip_${TIMESTAMP}.mp4"

  echo "Recording: $OUTPUT"

  # Record 5s clip directly to MP4

  rpicam-vid -t 5000 --nopreview --width 1280 --height 720 --codec h264 --bitrate 1500000 -o "$OUTPUT"

  # Upload to S3

  echo "Uploading to S3: s3://$BUCKET/$OUTPUT"

  aws s3 cp "$OUTPUT" "s3://$BUCKET/$OUTPUT"

  cd Desktop/shoplifting_engine
  source venv/bin/activate
  python3 inference_new.py

  # Optional: delete local copy after upload to save space

  # rm "$OUTPUT"

  sleep 0.5   # small delay

done
