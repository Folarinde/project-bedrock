output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.sessions.name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.sessions.arn
}

output "dynamodb_policy_arn" {
  description = "IAM policy ARN for DynamoDB access"
  value       = aws_iam_policy.dynamodb_access.arn
}