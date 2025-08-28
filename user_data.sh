#!/bin/bash

# Update and install necessary packages
sudo yum update -y
sudo yum install -y docker

# Start the Docker service
sudo systemctl start docker
sudo usermod -a -G docker ec2-user
newgrp docker

# Login to ECR
# Use the IAM role to get an ECR authentication token and log in to the registry
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Set environment variables for the application
export DB_PASSWORD="${db_password}"
export DB_HOST="${db_endpoint}"

# Run the Django application using Docker
docker run -p 5000:5000 ${ecr_repo_url}:latest