variable "student_id" {
  description = "Your student ID — makes the bucket name unique"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name — used for resource naming"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "bedrock-asset-processor"
}

variable "dev_user_arn" {
  description = "ARN of the bedrock-dev-view IAM user"
  type        = string
}