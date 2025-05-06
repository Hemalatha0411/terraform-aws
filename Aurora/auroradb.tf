data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.aws_secret_name
}

locals {
  db_username = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["username"]
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]
}

# Reference existing DB subnet group
data "aws_db_subnet_group" "aurora_private" {
  name = "aws-a0000-use1-00-t-sug-shrd-shr-prv01" # Change to your actual subnet group name
}

# Security group for Aurora PostgreSQL
resource "aws_security_group" "aurora_sg" {
  name        = var.aurora-sg
  description = "Security group for Aurora PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.244.40.0/22"] # Update with your actual CIDR range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aurora-sg"
  }
}

# Aurora PostgreSQL Cluster (Serverless v2)
resource "aws_rds_cluster" "aurora" {
  cluster_identifier                   = var.aurora_cluster_name
  engine                               = "aurora-postgresql"
  engine_mode                          = "provisioned"
  engine_version                       = "16.6"
  database_name                        = "cmmpoc"
  master_username                      = local.db_username
  master_password                      = local.db_password
  vpc_security_group_ids               = [aws_security_group.aurora_sg.id]
  db_subnet_group_name                 = data.aws_db_subnet_group.aurora_private.name
  iam_database_authentication_enabled = true

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4
  }

  storage_encrypted   = true
  skip_final_snapshot = true
}

# Aurora Cluster Instance
resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier          = var.aurora_instance_name
  cluster_identifier  = aws_rds_cluster.aurora.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.aurora.engine
  engine_version      = aws_rds_cluster.aurora.engine_version
  publicly_accessible = false
}
