output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.decilo_core_api.function_name
}
