output "sqs_queue_url" {
  description = "URL of the SQS messages queue"
  value       = aws_sqs_queue.messages.url
}

output "sqs_queue_arn" {
  description = "ARN of the SQS messages queue"
  value       = aws_sqs_queue.messages.arn
}

output "lambda_function_name" {
  description = "Name of the processor Lambda function"
  value       = aws_lambda_function.processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the processor Lambda function"
  value       = aws_lambda_function.processor.arn
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}
