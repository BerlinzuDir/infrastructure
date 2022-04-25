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
  function_name = "decilo-core-api"
  s3_bucket     = aws_s3_bucket.decilo_core_api.id
  s3_key        = data.aws_s3_object.decilo_core_api.key
  runtime       = "python3.8"
  handler       = "main.handler"
  role          = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "decilo_core_api" {
  name              = "/aws/lambda/${aws_lambda_function.decilo_core_api.function_name}"
  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless-lambda"

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

resource "aws_api_gateway_rest_api" "decilo_core" {
  name = "decilo-core"
}

resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.decilo_core.id
  resource_id   = aws_api_gateway_rest_api.decilo_core.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_integration" {
  rest_api_id             = aws_api_gateway_rest_api.decilo_core.id
  resource_id             = aws_api_gateway_rest_api.decilo_core.root_resource_id
  http_method             = aws_api_gateway_method.root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.decilo_core_api.invoke_arn
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.decilo_core.id
  parent_id   = aws_api_gateway_rest_api.decilo_core.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.decilo_core.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.decilo_core.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.decilo_core_api.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.decilo_core_api.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.decilo_core.execution_arn}/*/*/*"
}

resource "aws_api_gateway_deployment" "decilo_core" {
  rest_api_id = aws_api_gateway_rest_api.decilo_core.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.proxy_integration,
    aws_api_gateway_method.root,
    aws_api_gateway_integration.root_integration
  ]
}

resource "aws_api_gateway_stage" "decilo_core" {
  deployment_id = aws_api_gateway_deployment.decilo_core.id
  rest_api_id   = aws_api_gateway_rest_api.decilo_core.id
  stage_name    = "decilo-core"
}
