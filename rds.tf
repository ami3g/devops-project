# Define an Amazon RDS DB instance
resource "aws_db_instance" "devops_project_db" {
  # This makes the database part of your main VPC
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.devops_project_db_subnet_group.name

  # Database configuration
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16.10"
  instance_class         = "db.t3.micro"
  db_name                = "devops_project_db"
  username               = "projectadmin" # Changed from "admin" to "projectadmin"

  # Use a random password for security
  password               = random_password.devops_project_db_password.result

  # Use `apply_immediately` to allow changes without manual intervention (for learning purposes)
  apply_immediately      = true
  skip_final_snapshot    = true
  publicly_accessible    = false

  # Backup retention
  backup_retention_period = 7

  # Set a tag for easy identification
  tags = {
    Name = "devops-project-db"
  }

  # Prevent Terraform from recreating the DB instance on a simple engine version change
  lifecycle {
    ignore_changes = [engine_version]
  }
}

# Generate a random, secure password for the database
resource "random_password" "devops_project_db_password" {
  length  = 16
  special = true
  # Override the default special characters to exclude '/', '@', '"', and ' '
  override_special = "!#$%&*()_+-=[]{}|:<>?,."
}

# Create a database subnet group
resource "aws_db_subnet_group" "devops_project_db_subnet_group" {
  # Use the private subnets we've already defined
  subnet_ids = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  tags = {
    Name = "devops-project-db-subnet-group"
  }
}
