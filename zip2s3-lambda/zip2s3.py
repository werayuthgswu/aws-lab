import json
import boto3
import io
import os
import zipfile
from io import BytesIO

s3_client = boto3.client('s3')
dest_bucket = "destbucket-werayuth"

def lambda_handler(event, context):
    bucketname = event['Records'][0]['s3']['bucket']['name']
    file_key =  event['Records'][0]['s3']['object']['key']
    
    print(bucketname)
    print(file_key)
    
    #resp = s3obj.get_object(Bucket=bucketname, Key=file)

    try:
        # Download the file from the source bucket
        response = s3_client.get_object(Bucket=bucketname, Key=file_key)
        file_content = response['Body'].read()
        
        # Create an in-memory ZIP file
        zip_buffer = BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            zip_file.writestr(os.path.basename(file_key), file_content)
        
        # Seek to the beginning of the buffer
        zip_buffer.seek(0)
        
        # Define the zipped file key
        zip_file_key = f"{file_key}.zip"

        print(zip_file_key)
        
        # Upload the zipped file to the destination bucket
        s3_client.put_object(
            Bucket=dest_bucket,
            Key=zip_file_key,
            Body=zip_buffer.getvalue()
        )
        print(f"Zipped file uploaded to {dest_bucket}/{zip_file_key}")
        
        # Delete the original file from the source bucket
        s3_client.delete_object(Bucket=bucketname, Key=file_key)
        print(f"Original file deleted from {bucketname}/{file_key}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('File zipped and processed successfully!'),
            'bucket': bucketname,
            'zipped_file': f"{dest_bucket}/{zip_file_key}"
        }
    
    except Exception as e:
        print(f"Error processing file: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('Error processing file'),
            'error': str(e)
        }
