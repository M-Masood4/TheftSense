import os
import boto3
import botocore
from botocore.exceptions import ClientError
import partition_images as partition
import shutil
from pathlib import Path
import time

##
# The 'put_objects()' function was obtained from the AWS documentation.
#
# Before running this file, ensure the videos that you want to upload are placed in 'input_videos'.
# To save space in the S3 bucket, do not upload videos that you have already.
# Only files with the '.mp4' format will be uploaded.
#
# As of the most recent update of this file, this works on my local machine but i don't know
# if it will work on other machines. Also while the 'input_videos' are split, they are all
# uploaded to the same 'folder' in the bucket. 
##    

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
        print("ERROR")
        raise

def main():
    # Share the client session with functions and objects to benefit from S3 Express One Zone auth key
    s3_client = boto3.client('s3')

    #path = os.getcwd() + '/videos'
    directory_to_split = os.getcwd() + '/input_videos'

    #! check if path exists
    if os.path.exists(directory_to_split):

        #! delete previous test/train/val split if it exists so not uploading (CAUTION WHEN EDITING)
        folders = ['test','train','val']
        classes = ['negative','positive']
        for folder in folders:
            dir_to_del = os.getcwd() + '/' + folder
            if os.path.exists(dir_to_del):
                shutil.rmtree(dir_to_del)

        #! split input folder into test/train/val
        partition.partition(directory_to_split, 0.4, 0.3)

        paginator = s3_client.get_paginator('list_objects_v2')
        ###!!! pages = paginator.paginate('testbucket123347523')

        #! upload files to AWS bucket
        for folder in folders:
            base_dir_to_upload = os.getcwd() + '/' + folder

            for file_class in classes:
                dir_to_upload = base_dir_to_upload + '/' + file_class

                for file in os.scandir(dir_to_upload):
                    if file.is_file():# and file.name[-3:] == 'mp4':

                        #! use 'with' when working with files/databases as it correctly handles closing object locks
                        with open(file, 'rb') as f:
                            #! f.read() returns the file size
                            file_size = f.read()

                        ''' No Longer Using...
                        #! put_object(s3_client, <STR: bucket name on AWS>, <STR: file name>, <BYTE: file size>)
                        #resp = put_object(s3_client, 'testbucket123347523', os.path.basename(file), os.path.basename(file))
                        '''

                        path_in_bucket = folder + '/' + file_class + '/'

                        #! When uploading a file of the same name to a bucket, the old file is automatically overwritten.
                        #! to prevent this, the following block checks for the amount of files in a given folder and
                        #! changes the name of the file being uploaded to it.
                        #! Since I don't expect any files to be deleted from the bucket as is, this should work fine.
                        pages = paginator.paginate(Bucket='testbucket123347523', Prefix=path_in_bucket)
                        for page in pages:
                            if 'Contents' in page:
                                file_count = len(page['Contents'])
                            else:
                                file_count = 0
                        path_in_bucket += str(file_count) + '.jpg'

                        print('uploading ' + file.name + ' to ' + path_in_bucket)
                        s3_client.upload_file(file, 'testbucket123347523', path_in_bucket )

                        #! Now move uploaded files to the 'uploaded_videos' folder.
                        temp_num = str(len(os.listdir(os.getcwd() + '/uploaded_videos')))
                        #! files need to be renamed otherwise 'os.rename()' throws an error.
                        os.rename(file, os.getcwd() + '/uploaded_videos/' + temp_num + '.jpg')

                        #! finally, automatically delete 'input_videos' folder to avoid same files being reuploaded
                        if os.path.exists(os.getcwd() + '/input_videos'):
                            shutil.rmtree(os.getcwd() + '/input_videos')
                            os.mkdir(os.getcwd() + '/input_videos')
                            os.mkdir(os.getcwd() + '/input_videos/negative')
                            os.mkdir(os.getcwd() + '/input_videos/positive')

                    elif file.is_file():
                        print('File must contain the following extension: .mp4')
                        temp_num = str(len(os.listdir(os.getcwd() + '/failed_to_upload')))
                        os.rename(file, os.getcwd() + '/failed_to_upload/' + temp_num + '.jpg')
                    else:
                        print('File path does not exist')





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