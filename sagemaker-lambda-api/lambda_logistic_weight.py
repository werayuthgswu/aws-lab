import math
import json

def lambda_handler(event, context):
    
    # 1. Define Model Parameters
    # weights: (1, 5) | bias: (1,)
    weights = [1.93862641e-05, -5.79077720e-02, -5.32682963e-01, 5.12318597e-02, 4.06024953e-02]
    bias = 0.00076995
    
    try:
        # 2. Parse input data from the event
        # Expecting input as: {"features": [x1, x2, x3, x4, x5]}
        body = json.loads(event['body']) if 'body' in event else event
        features = body.get('features', [])
        
        if len(features) != len(weights):
            return {
                'statusCode': 400,
                'body': json.dumps(f"Expected {len(weights)} features, got {len(features)}")
            }

        # 3. Calculate Linear Combination (z = wx + b)
        # z = sum(w_i * x_i) + b
        z = sum(w * x for w, x in zip(weights, features)) + bias
        
        # 4. Apply Sigmoid Activation Function
        # sigmoid(z) = 1 / (1 + e^-z)
        probability = 1 / (1 + math.exp(-z))
        
        # 5. Determine Class (Threshold = 0.5)
        prediction = 1 if probability >= 0.5 else 0
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'probability': probability,
                'predicted_label': prediction,
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
