import boto3
from flask import Flask, jsonify
from flask_cors import CORS

s3 = boto3.client("s3", region_name="eu-west-1")

app = Flask(__name__)
CORS(app)

@app.route("/gen_url")
def gen_url():
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
        return jsonify({"url":url})
    except:
        print('lmao imagine failing')
        url = ''
        return jsonify({"url":"fail"})

if __name__ == "__main__":
    app.run()