# TODO: Define the output variable for the lambda function.
output "function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.test_lambda.arn
}

output "function_invoke_arn" {
  description = "The Invoke ARN of the Lambda function"
  value       = aws_lambda_function.test_lambda.invoke_arn
}

output "function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.test_lambda.function_name
}

output "function_qualified_arn" {
  description = "The qualified ARN of the Lambda function"
  value       = aws_lambda_function.test_lambda.qualified_arn
}

