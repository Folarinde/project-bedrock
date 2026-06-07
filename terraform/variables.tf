variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "project-bedrock-cluster"
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "project-bedrock-vpc"
}

variable "app_namespace" {
  description = "Kubernetes namespace for the retail app"
  type        = string
  default     = "retail-app"
}

variable "student_id" {
  description = "Your student ID for unique resource naming"
  type        = string
  # No default — This will be set it in terraform.tfvars
}

variable "db_username" {
  description = "Master username for RDS instances"
  type        = string
  default     = "bedrock_1"
}

variable "db_password" {
  description = "Master password for RDS instances"
  type        = string
  sensitive   = true  # Marks this as sensitive so it won't appear in logs
}

variable "console_password" {
  description = "Console login password for bedrock-dev-view IAM user"
  type        = string
  sensitive   = true
}