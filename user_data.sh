#!/bin/bash

# Update the system and install Docker
sudo yum update -y
sudo yum install -y docker

# Start and enable the Docker service
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Authenticate Docker with ECR
# Use the IAM role to get an ECR authentication token and log in
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 370936874275.dkr.ecr.us-east-1.amazonaws.com

# Set environment variables for the application
export DB_PASSWORD="${db_password}"
export DB_HOST="${db_endpoint}"

# Run the Django application using Docker
# The full ECR URI is required to pull from your private registry.
sudo docker run -p 5000:5000 370936874275.dkr.ecr.us-east-1.amazonaws.com/devops-project-app:latest