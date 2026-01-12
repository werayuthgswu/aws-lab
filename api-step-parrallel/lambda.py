import json
import urllib.request
# lambda
def lambda_handler(event, context):
    try:
        # Extract URL from the incoming event
        url = event.get("url")
        
        if not url:
            raise ValueError("Missing 'url' parameter in event")

        # Send HTTP request
        with urllib.request.urlopen(url) as response:
            data = response.read().decode("utf-8")
            json_data = json.loads(data)

        # Extract required fields
        country = json_data.get("country", "")
        places = json_data.get("places", [{}])
        city = places[0].get("place name", "")
        state = places[0].get("state", "")

        return {
            "statusCode": 200,
            "body": {
                "country": country,
                "state": state,
                "city": city
            }
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e)
            })

        }
