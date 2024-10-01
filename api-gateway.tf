# Create an API Gateway REST API for the Proxy Lambda
resource "aws_api_gateway_rest_api" "proxy_api" {
  name        = "ProxyAPI"
  description = "API Gateway for Proxy Lambda Function"
}

# Create an API Gateway Resource for the Proxy Lambda
resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.proxy_api.id
  parent_id   = aws_api_gateway_rest_api.proxy_api.root_resource_id
  path_part   = "proxy"
}

# Create a Method for the Proxy Resource (e.g., POST)
resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.proxy_api.id
  resource_id   = aws_api_gateway_resource.proxy_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integrate the API Gateway with the Proxy Lambda Function
resource "aws_api_gateway_integration" "proxy_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.proxy_api.id
  resource_id             = aws_api_gateway_resource.proxy_resource.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.proxy_lambda.invoke_arn
  integration_http_method = "POST"
}


# Grant API Gateway permission to invoke the Proxy Lambda function
resource "aws_lambda_permission" "proxy_api_gateway_lambda" {
  statement_id  = "AllowExecutionFromProxyAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.proxy_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.proxy_api.execution_arn}/*/*"
}
