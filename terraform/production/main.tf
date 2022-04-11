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
