provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "decilo-tf-state"
    key    = "network/terraform.tfstate"
    region = "eu-central-1"
  }
}

# decilo-core lambda

resource aws_s3_bucket decilo_core_api {
  bucket = "decilo-core-api"
}

data aws_s3_object decilo_core_api {
  bucket = aws_s3_bucket.decilo_core_api.bucket
  key    = "artifact.zip"
}

resource "aws_lambda_function" "decilo_core_api" {
  function_name = "decilo_core_api"
  s3_bucket     = aws_s3_bucket.decilo_core_api.id
  s3_key        = data.aws_s3_object.decilo_core_api.key
  runtime       = "python3.8"
  handler       = "decilo_core.main.handler"
  role          = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "decilo_core_api" {
  name              = "/aws/lambda/${aws_lambda_function.decilo_core_api.function_name}"
  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# API Gateway

resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.decilo_core_api_staging.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    }
    )
  }
}

resource "aws_apigatewayv2_integration" "decilo_core_api" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.decilo_core_api.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "hello" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.decilo_core_api.id}"

  depends_on = [aws_apigatewayv2_integration.decilo_core_api]
}

resource "aws_apigatewayv2_route" "routes" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /routes"
  target    = "integrations/${aws_apigatewayv2_integration.decilo_core_api.id}"

  depends_on = [aws_apigatewayv2_integration.decilo_core_api]

}

resource "aws_apigatewayv2_route" "shipments" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /shipments"
  target    = "integrations/${aws_apigatewayv2_integration.decilo_core_api.id}"

  depends_on = [aws_apigatewayv2_integration.decilo_core_api]

}

resource "aws_cloudwatch_log_group" "decilo_core_api_staging" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.decilo_core_api.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.lambda.invoke_url
}
