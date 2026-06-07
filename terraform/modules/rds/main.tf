# ─────────────────────────────────────────
# DB Subnet Group
# RDS must span at least 2 AZs
# ─────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name        = "${var.cluster_name}-db-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "Subnet group for project bedrock RDS instances"

  tags = {
    Name = "${var.cluster_name}-db-subnet-group"
  }
}

# ─────────────────────────────────────────
# Security Group — RDS Instances
# Only allows traffic from EKS worker nodes
# ─────────────────────────────────────────
resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Allow database access from EKS nodes only"
  vpc_id      = var.vpc_id

  # Allow MySQL traffic from EKS nodes only
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
    description     = "MySQL from EKS nodes"
  }

  # Allow PostgreSQL traffic from EKS nodes only
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
    description     = "PostgreSQL from EKS nodes"
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

# ─────────────────────────────────────────
# Secrets Manager — MySQL Credentials
# ─────────────────────────────────────────
resource "aws_secretsmanager_secret" "mysql" {
  name                    = "${var.cluster_name}/mysql/credentials"
  description             = "MySQL RDS credentials for retail app"
  recovery_window_in_days = 0   # set to 0 for easy cleanup after project

  tags = {
    Name = "${var.cluster_name}-mysql-secret"
  }
}

resource "aws_secretsmanager_secret_version" "mysql" {
  secret_id = aws_secretsmanager_secret.mysql.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = var.mysql_db_name
    engine   = "mysql"
    port     = 3306
    # host will be added after RDS is created
  })
}

# ─────────────────────────────────────────
# Secrets Manager — PostgreSQL Credentials
# ─────────────────────────────────────────
resource "aws_secretsmanager_secret" "postgres" {
  name                    = "${var.cluster_name}/postgres/credentials"
  description             = "PostgreSQL RDS credentials for retail app"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.cluster_name}-postgres-secret"
  }
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.postgres.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = var.postgres_db_name
    engine   = "postgres"
    port     = 5432
  })
}

# ─────────────────────────────────────────
# RDS — MySQL (Orders Service)
# ─────────────────────────────────────────
resource "aws_db_instance" "mysql" {
  identifier        = "${var.cluster_name}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.instance_class
  allocated_storage = 20          # 20GB minimum
  storage_type      = "gp2"

  db_name  = var.mysql_db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Security settings
  publicly_accessible     = false   # never expose DB to internet
  deletion_protection     = false   # set to true in real production
  skip_final_snapshot     = true    # set to false in real production
  backup_retention_period = 1       # keep 1 day of backups

  # Performance settings
  multi_az               = false    # single AZ to save cost for this project
  storage_encrypted      = true     # encrypt data at rest

  tags = {
    Name = "${var.cluster_name}-mysql"
  }
}

# Update the secret with the actual RDS endpoint after creation
resource "aws_secretsmanager_secret_version" "mysql_with_host" {
  secret_id = aws_secretsmanager_secret.mysql.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = var.mysql_db_name
    engine   = "mysql"
    port     = 3306
    host     = aws_db_instance.mysql.address
  })

  depends_on = [aws_db_instance.mysql]
}

# ─────────────────────────────────────────
# RDS — PostgreSQL (Catalog Service)
# ─────────────────────────────────────────
resource "aws_db_instance" "postgres" {
  identifier        = "${var.cluster_name}-postgres"
  engine            = "postgres"
  engine_version    = "15.12"
  instance_class    = var.instance_class
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.postgres_db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible     = false
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 1

  multi_az          = false
  storage_encrypted = true

  tags = {
    Name = "${var.cluster_name}-postgres"
  }
}

# Update the secret with the actual RDS endpoint after creation
resource "aws_secretsmanager_secret_version" "postgres_with_host" {
  secret_id = aws_secretsmanager_secret.postgres.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = var.postgres_db_name
    engine   = "postgres"
    port     = 5432
    host     = aws_db_instance.postgres.address
  })

  depends_on = [aws_db_instance.postgres]
}

