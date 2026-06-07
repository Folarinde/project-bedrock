output "mysql_endpoint" {
  description = "MySQL RDS endpoint"
  value       = aws_db_instance.mysql.address
}

output "mysql_port" {
  description = "MySQL RDS port"
  value       = aws_db_instance.mysql.port
}

output "mysql_db_name" {
  description = "MySQL database name"
  value       = aws_db_instance.mysql.db_name
}

output "mysql_secret_arn" {
  description = "ARN of the MySQL credentials secret"
  value       = aws_secretsmanager_secret.mysql.arn
}

output "postgres_endpoint" {
  description = "PostgreSQL RDS endpoint"
  value       = aws_db_instance.postgres.address
}

output "postgres_port" {
  description = "PostgreSQL RDS port"
  value       = aws_db_instance.postgres.port
}

output "postgres_db_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.postgres.db_name
}

output "postgres_secret_arn" {
  description = "ARN of the PostgreSQL credentials secret"
  value       = aws_secretsmanager_secret.postgres.arn
}

output "rds_security_group_id" {
  description = "Security group ID for RDS instances"
  value       = aws_security_group.rds.id
}