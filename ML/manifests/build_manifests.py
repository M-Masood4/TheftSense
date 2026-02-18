import boto3
import os

BUCKET = "testbucket123347523"
SPLITS = ["train", "val", "test"]
CLASSES = {
    "negative": 0,
    "positive": 1
}

OUTPUT_DIR = "manifests"


s3 = boto3.client("s3")

def list_s3_files(prefix):
    paginator = s3.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket = BUCKET, Prefix = prefix)

    files = []
    for page in pages:
        for obj in page.get("Contents", []):
            key = obj["Key"]
            if key.endswith(".mp4"):
                files.append(key)
    return files

def build_manifest(split):
    lines = []

    for cls, label in CLASSES.items():
        prefix = f"{split}/{cls}/"
        keys = list_s3_files(prefix)

        for key in keys:
            uri = f"s3://{BUCKET}/{key}"
            lines.append(f"{uri} {label}")

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    out_path = os.path.join(OUTPUT_DIR, f"{split}.txt")

    with open(out_path, "w") as f:
        f.write("\n".join(lines))

    print(f"Wrote {len(lines)} entries to {out_path}")

if __name__ == "__main__":
    for split in SPLITS:
        build_manifest(split)
