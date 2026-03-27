# ============================================================
#  MODULE: RDS
#  Creates: KMS key, DB subnet group, MySQL 8 RDS instance
# ============================================================

# ── KMS Key for RDS encryption ────────────────────────────────
resource "aws_kms_key" "rds" {
  description             = "${var.project_name} RDS encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = { Name = "${var.project_name}-rds-kms" }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ── DB Subnet Group (uses both data-layer private subnets) ────
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_data_subnet_ids

  tags = { Name = "${var.project_name}-db-subnet-group" }
}

# ── RDS Parameter Group ───────────────────────────────────────
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-mysql8-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = { Name = "${var.project_name}-mysql8-params" }
}

# ── RDS MySQL 8 Instance ──────────────────────────────────────
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.data_sg_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  # Encryption
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  # Availability – set multi_az = true for production
  multi_az               = false
  publicly_accessible    = false

  # Backups
  backup_retention_period = 7
  backup_window           = "02:00-03:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # CloudWatch logs: Error + SlowQuery (add "audit" for prod)
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  # Deletion protection – set true for production
  deletion_protection = false
  skip_final_snapshot = true

  tags = { Name = "${var.project_name}-mysql" }
}
