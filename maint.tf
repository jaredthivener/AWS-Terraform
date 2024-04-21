provider "aws" {
  region = var.region
}

# Create a customer managed key (CMK) in AWS KMS for encrypting RDS clusters
resource "aws_kms_key" "database_encryption_key" {
  description             = "CMK for RDS database encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Create a customer managed key (CMK) in AWS KMS for encrypting secrets in Secrets Manager
resource "aws_kms_key" "secrets_manager_encryption_key" {
  description             = "CMK for Secrets Manager encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Define a subnet group for the RDS cluster
resource "aws_db_subnet_group" "database_subnet_group" {
  name       = "database_subnet_group"
  subnet_ids = var.subnet_ids
}

# Define RDS database clusters
resource "aws_rds_cluster" "database_clusters" {
  for_each = var.databases

  cluster_identifier        = each.key
  database_name             = each.key
  engine                    = each.value.engine
  engine_version            = each.value.engine_version
  port                      = each.value.engine == "aurora-postgresql" ? 5432 : 3306
  master_username           = var.master_username
  master_password           = random_password.passwords[each.key].result
  backup_retention_period   = var.backup_retention_period
  preferred_backup_window   = "02:00-03:00"
  skip_final_snapshot       = true
  final_snapshot_identifier = "${each.key}-final"
  storage_encrypted         = true
  deletion_protection       = var.deletion_protection

  db_cluster_instance_class = each.value.instance_type
  db_subnet_group_name      = aws_db_subnet_group.database_subnet_group.name
  availability_zones        = slice(data.aws_availability_zones.available.names, 0, 3)

  apply_immediately                   = true
  iam_database_authentication_enabled = true

  kms_key_id = aws_kms_key.database_encryption_key.arn

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}

# Define RDS database instances
resource "aws_db_instance" "database_instances" {
  for_each = aws_rds_cluster.database_clusters

  identifier              = "${each.value.id}-instance"
  instance_class          = each.value.db_cluster_instance_class
  allocated_storage       = each.value.allocated_storage
  db_subnet_group_name    = aws_db_subnet_group.database_subnet_group.name
  engine                  = each.value.engine
  engine_version          = each.value.engine_version
  publicly_accessible     = false
  storage_encrypted       = true
  deletion_protection     = var.deletion_protection
  backup_retention_period = var.backup_retention_period

  monitoring_interval          = 10
  performance_insights_enabled = true

  performance_insights_kms_key_id = aws_kms_key.secrets_manager_encryption_key.arn
}

data "aws_availability_zones" "available" {}

resource "random_password" "passwords" {
  for_each = var.databases

  length           = 20
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}|;:'\"<>,.?/"
}

resource "aws_secretsmanager_secret" "db_passwords" {
  for_each = var.databases

  name = each.key

  kms_key_id = aws_kms_key.secrets_manager_encryption_key.arn
}

resource "aws_secretsmanager_secret_version" "db_password_versions" {
  for_each = var.databases

  secret_id     = aws_secretsmanager_secret.db_passwords[each.key].id
  secret_string = random_password.passwords[each.key].result
}

output "database_endpoints" {
  value = { for k, v in aws_rds_cluster.database_clusters : k => v.endpoint }
}
