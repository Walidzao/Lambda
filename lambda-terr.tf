# Set the required provider
provider "aws" {
  region = "us-east-1" # Specify your desired region
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "./lambda_function.zip"
  output_path = "/tmp/lambda.zip" #check the output path 
}


# Attach the necessary AWS managed policies to the IAM role (CloudWatch Logs, AWS Textract)
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "my_lambda" {
  function_name = "MyLambdaFunction"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  # Use the correct Layer ARNs with version 1 for Tesseract and Python libraries (pytesseract, Pillow)
  layers = [
    "arn:aws:lambda:us-east-1:786520870242:layer:tesseract-layer:1", # Tesseract layer
    "arn:aws:lambda:us-east-1:786520870242:layer:python-libraries:1" # Python libraries layer (pytesseract and Pillow)
  ]

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

# Output the function ARN and invoke URL (if used with API Gateway)
output "lambda_function_arn" {
  value = aws_lambda_function.my_lambda.arn
}



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