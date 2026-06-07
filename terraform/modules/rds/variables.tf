variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS placement"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group ID of EKS worker nodes"
  type        = string
}

variable "db_username" {
  description = "Master username for both RDS instances"
  type        = string
  default     = "bedrock_1"
}

variable "db_password" {
  description = "Master password for both RDS instances"
  type        = string
  sensitive   = true
}

variable "mysql_db_name" {
  description = "Initial database name for MySQL"
  type        = string
  default     = "bedrock_orders"
}

variable "postgres_db_name" {
  description = "Initial database name for PostgreSQL"
  type        = string
  default     = "bedrock_db"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"   
}

variable "cluster_name" {
  description = "EKS cluster name — used for resource naming"
  type        = string
}