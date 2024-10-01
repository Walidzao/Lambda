

# Create a deployment for the Proxy API Gateway
resource "aws_api_gateway_deployment" "proxy_deployment" {
  rest_api_id = aws_api_gateway_rest_api.proxy_api.id
  stage_name  = "prod"

  depends_on = [aws_api_gateway_integration.proxy_lambda_integration]
}
