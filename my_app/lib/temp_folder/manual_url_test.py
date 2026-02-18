import boto3
from flask import Flask, jsonify
from flask_cors import CORS
import requests

s3 = boto3.client('s3')

try:
    url = s3.generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket" : "t13-users-videos",
            "Key" : "test_clip.mp4",
            "ContentType" : "video/mp4"
        },
        ExpiresIn=86400
    )
    
    with open("lib/temp_folder/test_clip.mp4", "rb") as file:
        response = requests.put(
            url, 
            data=file, 
            headers={"Content-Type":"video/mp4"})

    access_url = s3.generate_presigned_url(
        ClientMethod="get_object",
        Params={
            "Bucket":"t13-users-videos",
            "Key":"test_clip.mp4"
        },
        ExpiresIn=86400
    )

    print(access_url)

except Exception as e:
    print(e)

#https://t13-users-videos.s3.amazonaws.com/test_clip.mp4?AWSAccessKeyId=AKIAS7AA52XPFUBU4YPV&Signature=u8r7ZI2D5Vgu0BQqMUYX3BClTxo%3D&content-type=video%2Fmp4&Expires=1771525538 
