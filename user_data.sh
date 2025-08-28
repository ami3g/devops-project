#!/bin/bash

# Update the system and install Docker
sudo yum update -y
sudo yum install -y docker

# Start and enable the Docker service
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
# The `newgrp` command is needed to apply the group change immediately
newgrp docker

# Authenticate Docker with ECR
# Use the IAM role to get an ECR authentication token and log in
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${ecr_repo_url}

# Run the application using Docker
# Pass the database credentials and endpoint as environment variables
# Run in the background (-d) and restart automatically
sudo docker run -d \
  --restart=always \
  -p 8000:8000 \
  --env DB_PASSWORD="${db_password}" \
  --env DB_HOST="${db_endpoint}" \
  ${ecr_repo_url}:latest
