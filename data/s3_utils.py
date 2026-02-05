import os
import boto3

from dotenv import load_dotenv
load_dotenv("keys.env")

s3 = boto3.client("s3")

def parse_s3_uri(s3_uri):
    """
    Parses s3://bucket/path/to/file
    """
    assert s3_uri.startswith("s3://")
    path = s3_uri.replace("s3://", "")
    bucket, key = path.split("/", 1)
    return bucket, key

def download_if_needed(s3_uri, cache_root="s3_cache"):

    """
    Downloads as S3 object into a local cache if it does not exist.

    Args:
        s3_uri (str): s3://bucket/path/to/vidoe.mp4
        catche_root (str): local cache directory

    Returns:
        str: local file path
    """

    bucket, key = parse_s3_uri(s3_uri)
    local_path = os.path.join(cache_root, key)

    os.makedirs(os.path.dirname(local_path), exist_ok=True)

    if not os.path.exists(local_path):
        s3.download_file(bucket, key, local_path)

    return local_path