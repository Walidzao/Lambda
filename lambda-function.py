import base64
import boto3
import io

# Initialize the Textract client
textract = boto3.client('textract')

def lambda_handler(event, context):
    # The event contains the base64 image in event['image_data']
    base64_image = event.get('image_data')

    if not base64_image:
        return {
            'statusCode': 400,
            'body': 'No image data found in the request'
        }

    # Decode the base64 image
    try:
        image_data = base64.b64decode(base64_image)
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Failed to decode image: {str(e)}'
        }

    # Call AWS Textract to extract text from the image
    try:
        response = textract.detect_document_text(
            Document={'Bytes': image_data}
        )
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Failed to extract text using Textract: {str(e)}'
        }

    # Extract text from the Textract response
    extracted_text = ''
    for item in response['Blocks']:
        if item['BlockType'] == 'LINE':
            extracted_text += item['Text'] + '\n'

    # Return the extracted text
    return {
        'statusCode': 200,
        'body': extracted_text
    }
