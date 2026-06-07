variable "cluster_name" {
  description = "EKS cluster name — used for table naming"
  type        = string
}

variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "retail-sessions"
}