import boto3

# Initialize the S3 client (Boto3 will automatically look for AWS credentials)
aws_access_key_id = ""
aws_secret_access_key = ""
aws_session_token = ""

# Initialize the S3 client with explicit credentials
s3_client = boto3.client(
    's3',
    region_name='us-east-1',  # Change to your region
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    aws_session_token=aws_session_token  # Remove if not using temporary credentials
)
# Define your bucket and object details
bucket_name = 's3-demo-werayuth'
object_key = 'index.html'

try:
    # Read the object from the bucket
    response = s3_client.get_object(Bucket=bucket_name, Key=object_key)

    # Read the object's content as text and decode it (assuming UTF-8)
    object_content = response['Body'].read().decode('utf-8')

    # Process or use the content as needed
    print(f"Contents of {object_key}:")
    print("-" * 20)
    print(object_content)

except Exception as e:
    print(f"Error reading object: {e}")