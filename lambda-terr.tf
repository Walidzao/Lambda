# Set the required provider
provider "aws" {
  region = "us-east-1" # Specify your desired region
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./lambda_package"
  output_path = "/tmp/lambda.zip" #check the output path 
}

# Archive the Proxy Lambda function
data "archive_file" "proxy_lambda_zip" {
  type        = "zip"
  source_file = "./lambda-proxy-function.py" # Path to your Proxy Lambda function
  output_path = "/tmp/proxy_lambda.zip"
}

# IAM Role for Lambda with necessary permissions
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the necessary AWS managed policies to the IAM role (CloudWatch Logs, AWS Textract)
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Add inline policy for the proxy Lambda to invoke the main OCR Lambda
resource "aws_iam_policy" "lambda_invoke_policy" {
  name        = "lambda_invoke_policy"
  description = "Policy to allow Proxy Lambda to invoke the OCR Lambda"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "${aws_lambda_function.my_lambda.arn}"
    }
  ]
}
EOF
}

# Attach the inline policy to the lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_invoke_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_invoke_policy.arn
}

# Main OCR Lambda function
resource "aws_lambda_function" "my_lambda" {
  function_name = "MyLambdaFunction"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"


  timeout = 20 # Extend the timeout to 15 seconds

  # Use the correct Layer ARNs with version 1 for Tesseract and Python libraries (pytesseract, Pillow)
  layers = [
    "arn:aws:lambda:us-east-1:786520870242:layer:tesseract-layer:1",   # Tesseract layer
    "arn:aws:lambda:us-east-1:786520870242:layer:python-libraries:1",  # Python libraries layer (pytesseract and Pillow)
    "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p38-pillow:1" # pillow layer from the internet. 
  ]

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

# Create the Proxy Lambda Function that triggers the OCR Lambda
resource "aws_lambda_function" "proxy_lambda" {
  function_name = "ProxyLambdaFunction"
  handler       = "lambda-proxy-function.lambda_handler"
  runtime       = "python3.8"


  timeout = 30

  filename         = data.archive_file.proxy_lambda_zip.output_path
  source_code_hash = data.archive_file.proxy_lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_exec.arn
}

# Attach permissions for the Proxy Lambda to invoke the OCR Lambda
# Attach permissions for the Proxy Lambda to invoke the OCR Lambda
resource "aws_lambda_permission" "invoke_permission" {
  statement_id  = "AllowInvocationOfOCRLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "lambda.amazonaws.com"

  # Grant permission specifically to the Proxy Lambda
  source_arn = aws_lambda_function.proxy_lambda.arn
}



# Output the function ARN and invoke URL (if used with API Gateway)
output "lambda_function_arn" {
  value = aws_lambda_function.my_lambda.arn
}

