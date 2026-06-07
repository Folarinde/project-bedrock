# main.tf — Root Module

# ─────────────────────────────────────────
# VPC Module
# ─────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  vpc_name             = var.vpc_name
  cluster_name         = var.cluster_name
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
}

# Module blocks will be added here as each module is built:
# ─────────────────────────────────────────
# EKS Module
# ─────────────────────────────────────────
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  cluster_version    = "1.34"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  node_instance_type = "t3.small"
  node_desired_size  = 2
  node_min_size      = 1
  node_max_size      = 3
}

# ─────────────────────────────────────────
# RDS Module
# ─────────────────────────────────────────
module "rds" {
  source = "./modules/rds"

  cluster_name           = var.cluster_name
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  node_security_group_id = module.eks.node_security_group_id
  db_username            = var.db_username
  db_password            = var.db_password
  mysql_db_name          = "bedrock_orders"
  postgres_db_name       = "bedrock_db"
  instance_class         = "db.t3.micro"
}

# ─────────────────────────────────────────
# DynamoDB Module
# ─────────────────────────────────────────
module "dynamodb" {
  source = "./modules/dynamodb"

  cluster_name = var.cluster_name
  table_name   = "retail-sessions"
}

locals {
  assets_bucket_name = "bedrock-assets-${var.student_id}"
  assets_bucket_arn  = "arn:aws:s3:::bedrock-assets-${var.student_id}"
}

# ─────────────────────────────────────────
# S3 + Lambda Module
# ─────────────────────────────────────────
module "s3_lambda" {
  source = "./modules/s3_lambda"

  student_id           = var.student_id
  cluster_name         = var.cluster_name
  lambda_function_name = "bedrock-asset-processor"
  dev_user_arn         = module.iam.dev_user_arn

  depends_on = [module.iam]
}

# ─────────────────────────────────────────
# IAM Module
# ─────────────────────────────────────────
module "iam" {
  source = "./modules/iam"

  dev_username      = "bedrock-dev-view"
  cluster_name      = var.cluster_name
  assets_bucket_arn = local.assets_bucket_arn
  console_password  = var.console_password

  depends_on = [module.eks]
}