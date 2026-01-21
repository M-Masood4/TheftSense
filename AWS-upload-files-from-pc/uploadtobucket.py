import os
import boto3
import botocore
from botocore.exceptions import ClientError
import partition_images as partition
import shutil

    
def put_object(s3_client, bucket_name, key_name, object_bytes):
    """  
    Upload data to a directory bucket.
    :param s3_client: The boto3 S3 client
    :param bucket_name: The bucket that will contain the object
    :param key_name: The key of the object to be uploaded
    :param object_bytes: The data to upload
    """
    try:
        response = s3_client.put_object(Bucket=bucket_name, Key=key_name,
                             Body=object_bytes)
        print(f"Upload object '{key_name}' to bucket '{bucket_name}'.") 
        return response
    except ClientError:    
        print(f"Couldn't upload object '{key_name}' to bucket '{bucket_name}'.")
        raise

def main():
    # Share the client session with functions and objects to benefit from S3 Express One Zone auth key
    s3_client = boto3.client('s3')

    #path = os.getcwd() + '/videos'
    directory_to_split = os.getcwd() + '/images'

    #! check if path exists
    if os.path.exists(directory_to_split):
        #! delete previous test/train/val split if it exists so not uploading (CAUTION WHEN EDITING)
        folders = ['test','train','val']
        classes = ['negative','positive']
        for folder in folders:
            dir_to_del = os.getcwd() + '/' + folder
            shutil.rmtree(dir_to_del)

        #! split input folder into test/train/val
        partition.partition(directory_to_split, 0.4, 0.3)

        #! upload files to AWS bucket
        for folder in folders:
            base_dir_to_upload = os.getcwd() + '/' + folder
            for file_class in classes:
                dir_to_upload = base_dir_to_upload + '/' + file_class
                for file in os.scandir(dir_to_upload):
                    if file.is_file(): #!! and file.name[-3:] == 'mp4':
                        #! use 'with' when working with files/databases as it correctly handles closing object locks
                        #! f.read() return the file size
                        with open(file, 'rb') as f:
                            file_size = f.read()

                        print('uploading: ' + file.name)

                        #! put_object(s3_client, <STR: bucket name on AWS>, <STR: file name>, <BYTE: file size>)
                        resp = put_object(s3_client, 'testbucket123347523', os.path.basename(file), file_size)
                        #print(resp)
                    else:
                        print("Path doesn't exist")


if __name__ == "__main__":
    ### MAIN PROGRAM

    main()

    print("finished executing without errors")
    

    ### TESTING
    '''
    session = boto3.Session() 
    print(session.get_credentials().access_key) 
    print(session.get_credentials().secret_key) 
    print(session.region_name)
    '''