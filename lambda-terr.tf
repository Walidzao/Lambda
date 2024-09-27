# Set the required provider
provider "aws" {
  region = "us-east-1" # Specify your desired region
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "./lambda_function.zip"
  output_path = "/tmp/lambda.zip" #check the output path 
}


resource "aws_lambda_function" "my_lambda" {
  function_name = "MyLambdaFunction"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
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