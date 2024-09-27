import base64
import boto3
import io
import pytesseract
from PIL import Image

# Initialize the AWS Textract client
textract = boto3.client('textract')

def tesseract_ocr_with_confidence(image):
    # Get OCR result with confidence scores
    data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)
    extracted_text = ""
    total_confidence = 0
    count = 0

    # Iterate over the words detected
    for i in range(len(data['text'])):
        if int(data['conf'][i]) > 0:  # Valid confidence score
            extracted_text += data['text'][i] + " "
            total_confidence += int(data['conf'][i])
            count += 1

    avg_confidence = total_confidence / count if count > 0 else 0
    return extracted_text, avg_confidence

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
        image = Image.open(io.BytesIO(image_data))
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Failed to decode image: {str(e)}'
        }

    # Process the image using Tesseract OCR with confidence scores
    try:
        tesseract_text, tesseract_avg_confidence = tesseract_ocr_with_confidence(image)
    except Exception as e:
        tesseract_text = None
        tesseract_avg_confidence = 0

    # Process the image using AWS Textract
    try:
        textract_response = textract.detect_document_text(
            Document={'Bytes': image_data}
        )
        textract_text = ''
        textract_total_confidence = 0
        textract_block_count = 0

        for item in textract_response['Blocks']:
            if item['BlockType'] == 'LINE':
                textract_text += item['Text'] + '\n'
                textract_total_confidence += item.get('Confidence', 0)
                textract_block_count += 1

        textract_avg_confidence = (
            textract_total_confidence / textract_block_count if textract_block_count > 0 else 0
        )

    except Exception as e:
        textract_text = None
        textract_avg_confidence = 0

    # Compare the confidence scores from Tesseract and AWS Textract
    if tesseract_avg_confidence > textract_avg_confidence:
        final_text = tesseract_text
        confidence_source = "Tesseract"
    else:
        final_text = textract_text
        confidence_source = "AWS Textract"

    # Return the final result
    return {
        'statusCode': 200,
        'body': {
            'extracted_text': final_text,
            'source': confidence_source,
            'tesseract_confidence': tesseract_avg_confidence,
            'textract_confidence': textract_avg_confidence
        }
    }
