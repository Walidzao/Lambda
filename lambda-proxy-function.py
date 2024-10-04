import json
import boto3

# Initialize the AWS Lambda client
lambda_client = boto3.client('lambda')

def lambda_handler(event, context):
    # Extract the base64 image data from the event
    base64_image_data = event.get('image_data')
    
    if not base64_image_data:
        return {
            'statusCode': 400,
            'body': json.dumps('No image data found in the request')
        }

    # Prepare the payload to send to the first Lambda function
    payload = {
        'image_data': base64_image_data
    }

    try:
        # Invoke the first Lambda function
        response = lambda_client.invoke(
            FunctionName='MyLambdaFunction',  # Replace with the name of the first Lambda function
            InvocationType='RequestResponse',       # This waits for a response
            Payload=json.dumps(payload)
        )
        
        # Parse the response from the first Lambda function
        response_payload = json.loads(response['Payload'].read().decode('utf-8'))
        
        # Check if the first Lambda returned an error
        if response_payload.get('statusCode') != 200:
            return {
                'statusCode': 500,
                'body': json.dumps('Error from OCR Lambda function: ' + str(response_payload.get('body')))
            }

        # Return the result from the first Lambda function
        return {
            'statusCode': 200,
            'body': json.dumps(response_payload.get('body'))
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Failed to invoke the first Lambda function: {str(e)}')
        }
