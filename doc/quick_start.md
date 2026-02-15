# Quick Start Manual for AWS Lambda with Tesseract OCR

## Overview
This project deploys an AWS Lambda function that utilizes Tesseract OCR and Pillow for image processing. The Lambda function is exposed via an AWS API Gateway. This manual will guide you through setting up your environment, deploying the resources, and testing the functionality.

## Prerequisites
Before you begin, ensure you have the following installed:

*   **AWS CLI:** Configure with appropriate credentials.
    ```bash
    aws configure
    ```
*   **Terraform:** For deploying the AWS infrastructure.
    ```bash
    brew install terraform # macOS
    # Or follow official documentation for other OS: https://learn.hashicorp.com/tutorials/terraform/install-cli
    ```
*   **Python 3.8+:** For developing and packaging the Lambda function.
    ```bash
    python --version
    ```
*   **pip:** Python package installer.
    ```bash
    pip --version
    ```

## Environment Setup

1.  **Clone the Repository:**
    ```bash
    git clone <repository_url>
    cd Lambda # or your project directory
    ```

2.  **Install Python Dependencies:**
    The Lambda function requires `pytesseract` and `Pillow`. These are packaged as a Lambda layer.
    You can create the layer by running the appropriate script or by using the provided `pillow_layer.zip` and `tesseract-layer.zip` if available.

    To create the Python dependencies locally for the Lambda function:
    ```bash
    mkdir -p python/lib/python3.8/site-packages
    pip install -t python/lib/python3.8/site-packages pytesseract Pillow
    zip -r python-libraries.zip python/
    ```

    *Note: The project structure indicates pre-built layers like `pillow_layer/pillow_layer.zip` and `tesseract-layer.zip`. You might need to adjust the deployment if these are already used as layers.*

## Deployment

1.  **Initialize Terraform:**
    Navigate to the root of your project where the `.tf` files are located.
    ```bash
    terraform init
    ```

2.  **Review the Plan (Optional but Recommended):**
    This command shows you what AWS resources Terraform will create, modify, or destroy.
    ```bash
    terraform plan
    ```

3.  **Apply the Terraform Configuration:**
    This command will deploy all the AWS resources defined in the `.tf` files (Lambda function, API Gateway, etc.).
    ```bash
    terraform apply
    ```
    Type `yes` when prompted to confirm the deployment.

## Testing

Once the deployment is complete, Terraform will output the API Gateway endpoint URL.

1.  **Get API Gateway Endpoint:**
    Look for an output variable named `api_gateway_url` or similar in the `terraform apply` output. If not, you can find it in the AWS console under API Gateway.

2.  **Test with `curl`:**
    You can test the Lambda function via the API Gateway using `curl`. The Lambda function expects a base64 encoded image in the request body.

    First, convert an image to base64. For example, if you have `image.png`:
    ```bash
    base64 -i image.png > image_base64.txt
    ```
    Then, send a POST request to your API Gateway endpoint:
    ```bash
    API_URL="YOUR_API_GATEWAY_URL"
    IMAGE_BASE64=$(cat image_base64.txt)

    curl -X POST "$API_URL" \
         -H "Content-Type: application/json" \
         -d "{\"image\": \"$IMAGE_BASE64\"}"
    ```
    Replace `YOUR_API_GATEWAY_URL` with the actual URL.

    The response should contain the OCR-extracted text from the image.

## Troubleshooting

*   **Lambda Execution Errors:** Check AWS CloudWatch logs for your Lambda function for detailed error messages.
*   **API Gateway Errors:** Use the API Gateway logs (if enabled) to diagnose issues with requests.
*   **Terraform Errors:** Review the `terraform apply` output carefully for any configuration errors.

This quick start guide should get you up and running with your AWS Lambda Tesseract OCR project.
