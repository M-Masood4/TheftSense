# Team 13 Software Project

## Important Note
This system relies on Amazon Web Services (AWS) and Google Firebase to function. As of uploading this project, the relevant AWS S3 and firebase resources might no longer be available and thus some functions of the Flutter Web Application might not working as intended.

To run this project you must run the following commands:
1. **cd GroupProject/my_app**
2. **python lib/aws_api_calls.py** (for AWS services).
3. either navigate to **lib/main.dart** and press the button on the top right to start running the Flutter application or type **flutter run** in the terminal.

## The Machine Learning Model
All relevant ML files are located in **GroupProject/ML**. These include demo outputs and the python file to run inference.

Also included is GroupProject/AWS-upload-files-from-pc, this directory includes python files to split a folder of input videos into training, testing, and validation folders, each with positive and negative subclass folders which are subsequently uploaded to an AWS S3 bucket. During training, the model pulls relevant files from the bucket.

## Flutter
TheftSense(rights reserved?) was developed using the Flutter framework for Flutter Web. Please note that trying to run this application on an android emulator will cause some issues. It is recommended to run it on a browser (eg: chrome, edge).

While there looks to be many files, the meat of the project is located in **GroupProject/my_app/lib/**, the rest of the files are configuration files to make the app work on multiple platforms and to download various dependencies.

## Amazon Web Services
Using the AWS SDK for python we can upload/download files from S3 bucket or generate urls to access videos from the app. Files such as

1. uploadtobucket.py
2. aws_api_calls.py

use the boto3 client included in the SDK to connect to, and manage S3 buckets. You are required to run the Flask app as Flutter makes calls to it while running to fetch resources from buckets. (eg: downloading 'incidents' that end up being displayed in the app's history page).

As stated previously, these resources might be deleted after submission due to free-tier account limits. Also, the AWS SDK requires users to configure keys in their workspace (**aws configure**) before accessing resources which might also cause errors.

Here is an example of a 'policy' (written in JSON) that is attached to a user. As AWS has many security restrictions, this allows the chosen 'user' to access bucket resources:
```json
{

	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": "s3:ListAllMyBuckets",
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"s3:ListBucket",
				"s3:GetBucketLocation"
			],
			"Resource": [
				"arn:aws:s3:::testbucket123347523",
				"arn:aws:s3:::t13-users-videos",
				"arn:aws:s3:::t13-marked-videos"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
				"s3:GetObject",
				"s3:PutObject",
				"s3:DeleteObject",
				"s3:AbortMultipartUpload",
				"s3:ListMultipartUploadParts"
			],
			"Resource": [
				"arn:aws:s3:::testbucket123347523/*",
				"arn:aws:s3:::t13-users-videos/*",
				"arn:aws:s3:::t13-marked-videos/*"
			]
		}
	]
}
```
And here is a policy attached to an S3 bucket which allows CORS (Cross Origin Resource Sharing) access, allowing the app to make requests from a browser:
```json
[
    
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "GET"
        ],
        "AllowedOrigins": [
            "*"
        ],
        "ExposeHeaders": []
    }
]
```

