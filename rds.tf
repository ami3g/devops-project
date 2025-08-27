# Define an Amazon RDS DB instance
resource "aws_db_instance" "devops_project_db" {
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.devops_project_db_subnet_group.name

  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "16.10"
  instance_class          = "db.t3.micro"
  db_name                 = "devops_project_db"
  username                = "projectadmin"
  password                = random_password.devops_project_db_password.result

  apply_immediately       = true
  skip_final_snapshot     = true
  publicly_accessible     = false
  backup_retention_period = 7

  tags = {
    Name = "devops-project-db"
  }

  lifecycle {
    ignore_changes = [engine_version]
  }
}

resource "random_password" "devops_project_db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()_+-=[]{}|:<>?,."
}

resource "aws_db_subnet_group" "devops_project_db_subnet_group" {
  subnet_ids = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  tags = {
    Name = "devops-project-db-subnet-group"
  }
}

# Create a new secret for the DB password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password_secret" {
  name        = "devops-project-db-password"
  description = "RDS DB password"
}

resource "aws_secretsmanager_secret_version" "db_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_password_secret.id
  secret_string = random_password.devops_project_db_password.result
}

# Create a new secret for the DB endpoint
resource "aws_secretsmanager_secret" "db_endpoint_secret" {
  name        = "devops-project-db-endpoint"
  description = "RDS DB endpoint"
}

resource "aws_secretsmanager_secret_version" "db_endpoint_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_endpoint_secret.id
  secret_string = aws_db_instance.devops_project_db.address
}
