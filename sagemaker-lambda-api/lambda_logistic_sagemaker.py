import boto3
import json
import os

# Initialize the SageMaker runtime client
sagemaker_runtime = boto3.client('sagemaker-runtime')

def lambda_handler(event, context):
    """
    Calls a SageMaker Serverless endpoint using Boto3.
    """
    # 1. Define endpoint details
    # Note: Use the NAME of the endpoint, not the full URL
    endpoint_name = "linear-classifier-v1-serverless"
    
    print('raw event: ', event)
    try:
        # 1. API Gateway sends the payload as a STRING in 'body'
        if 'body' in event:
            # 2. Parse the string into a dictionary
            body_dict = json.loads(event['body'])
        
             # 3. Get the features from the dictionary
            features = body_dict.get('features')
            #return {"statusCode": 400, "body": json.dumps("No body found")}
        elif  'features' in event:   
            features = event.get('features')
        
            if features is None:
                return {
                    "statusCode": 400,
                    "body": json.dumps({"error": "Missing features", "event_received": event})
                }
        else:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing 'features' in request body"})
            }
            
        
        # Format for SageMaker: "0.5,1.2,-0.3,0.8,0.1"
        payload = ",".join(map(str, features))

        # 3. Invoke the SageMaker Endpoint
        response = sagemaker_runtime.invoke_endpoint(
            EndpointName=endpoint_name,
            ContentType='text/csv',
            Body=payload
        )
        
        # 4. Parse the response
        # The response Body is a streaming object, we must read() it
        result = json.loads(response['Body'].read().decode())
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(result)
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to invoke SageMaker endpoint', 'details': str(e)})
        }
