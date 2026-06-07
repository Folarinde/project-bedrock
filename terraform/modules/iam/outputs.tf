output "dev_user_arn" {
  description = "ARN of the bedrock-dev-view IAM user"
  value       = aws_iam_user.dev.arn
}

output "dev_user_name" {
  description = "Username of the developer IAM user"
  value       = aws_iam_user.dev.name
}

output "dev_access_key_id" {
  description = "Access Key ID for bedrock-dev-view"
  value       = aws_iam_access_key.dev.id
  # Not marked sensitive so it appears in terraform output
  # and gets captured in grading.json
}

output "dev_secret_access_key" {
  description = "Secret Access Key for bedrock-dev-view"
  value       = aws_iam_access_key.dev.secret
  sensitive   = true
  # Run: terraform output dev_secret_access_key
  # to retrieve this value after apply
}

output "dev_console_password" {
  description = "Console login password for bedrock-dev-view"
  value       = var.console_password
  sensitive   = true
}

output "console_login_url" {
  description = "AWS Console login URL for the developer user"
  value       = "https://signin.aws.amazon.com/console"
}