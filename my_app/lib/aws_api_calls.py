import boto3
from flask import Flask, jsonify, request
from flask_cors import CORS
import requests

s3 = boto3.client("s3", region_name="eu-west-1")

app = Flask(__name__)
CORS(app)

# IMPORTANT: 
# It is impossible to start a flask app from
# flutter web, if you are using this, you need
# to manually start flask like this:
#
# python py_gen_vid_url.py
# 
# this should work well enough for the demo.

@app.route("/gen_url")
### user: currently logged in user in flutter app,
###       will be the folder in the bucket.
### file_path: path to video on system.
def gen_url():

    user = request.args.get("user")
    file_path = request.args.get("file_path")

    ### check if file being uploaded is .mp4
    directories = file_path.split("/")
    file_name = directories[-1]

    if file_name[-4:] == ".mp4":

        try:
            ### request url to allow app to upload video
            url = s3.generate_presigned_url(
                ClientMethod="put_object",
                Params={
                    "Bucket" : "t13-users-videos",
                    "Key" : user + '/' + file_name,
                    "ContentType" : "video/mp4"
                },
                ExpiresIn=86400
            )
            
            ### upload video to bucket
            with open(file_path, "rb") as file:
                response = requests.put(
                    url, 
                    data=file, 
                    headers={"Content-Type":"video/mp4"})

            ### generate url to allow app to display
            ### video, when link expires, the related
            ### 'Incident' should be deleted from history.
            access_url = s3.generate_presigned_url(
                ClientMethod="get_object",
                Params={
                    "Bucket": "t13-users-videos",
                    "Key": user + '/' + file_name
                },
                ExpiresIn=86400
            )
            print(access_url)
            return access_url

        except Exception as e:
            print(e)
            return "error"

    else:
        print("Only files with '.mp4' extension can be uploaded!")
        return "error"
    
### NEXT FUNCTION

@app.route("/fetch_incidents")
def fetch_incidents():
    user = request.args.get("user") + '/'

    try:
        ### generate url for each video and store in 'links'
        links = []

        paginator = s3.get_paginator("list_objects_v2")

        for page in paginator.paginate(Bucket='t13-marked-videos', Prefix=user):
            for video in page.get("Contents", []):
                key = video["Key"]

                links.append(s3.generate_presigned_url(
                    ClientMethod="get_object",
                    Params={
                        "Bucket": "t13-marked-videos",
                        "Key": key
                    },
                    ExpiresIn=86400
                ))

        return links


    except Exception as e:
        print(e)



if __name__ == "__main__":
    app.run()