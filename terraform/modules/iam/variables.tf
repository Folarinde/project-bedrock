variable "dev_username" {
  description = "IAM username for the developer user"
  type        = string
  default     = "bedrock-dev-view"
}

variable "assets_bucket_arn" {
  description = "ARN of the S3 assets bucket"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "console_password" {
  description = "Console login password for the developer user"
  type        = string
  sensitive   = true
}