# Lambda test
{
  "body": "{\"features\": [0.5, 1.2, -0.3, 0.8, 0.121]}"
}

# API Gateway (REST API)
/logistic
  POST

Deploy on dev

# Curl test

curl -X POST https://wvib8vwt80.execute-api.us-east-1.amazonaws.com/dev/logistic      -H "Content-Type: application/json"      -d '{"features": [0.5, 1.2, -0.3, 0.8, 0.1]}'

## expect output
{"statusCode": 200, "headers": {"Content-Type": "application/json"}, "body": "[1.0]"} 


