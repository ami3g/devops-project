# DevOps Project

A full-lifecycle DevOps pipeline for deploying a scalable, resilient **ecommerce Django web application** on AWS.  
This project demonstrates modern cloud infrastructure, automation, and security best practices.

---

## Project Stack

- **Application:** Django (Python) — Ecommerce site
- **Database:** AWS RDS PostgreSQL
- **Containerization:** Docker
- **Infrastructure as Code:** Terraform
- **CI/CD:** GitHub Actions
- **Cloud Provider:** AWS (EC2, ALB, ASG, RDS, S3, ECR)
- **Security:** Bastion Host, Security Groups
- **Monitoring:** CloudWatch, Health Checks
- **Vulnerability Scanning:** Trivy

---

## Features

- **Ecommerce Functionality:** Product listing, admin management, and extensible for cart/checkout.
- **Automated Infrastructure:** Provision AWS resources using Terraform.
- **CI/CD Pipeline:** Build, scan, and deploy Docker images via GitHub Actions.
- **Scalable Architecture:** Auto Scaling Group for high availability.
- **Secure Access:** Bastion host for admin SSH; security groups for segmentation.
- **Monitoring & Logging:** Health checks and CloudWatch integration.
- **Persistent Storage:** RDS PostgreSQL and optional S3 for static/media files.
- **Admin Panel:** Django admin for product/user management.

---

## Architecture Overview

The diagram below illustrates the end-to-end flow:  
- **Users** access the web app via the Load Balancer.
- **Admins/DevOps** access EC2 instances securely via the Bastion Host.
- **CI/CD pipeline** automates build, security scan, and deployment.
- **Auto Scaling Group** maintains multiple app servers for reliability.
- **Database and storage** are managed via AWS RDS and S3.

```mermaid
flowchart TD
    %% Users
    User["User (Browser)"]
    Admin["Admin/DevOps (SSH)"]
    style User fill:#f9f,stroke:#333,stroke-width:2px
    style Admin fill:#d7bde2,stroke:#333,stroke-width:2px

    %% CI/CD Pipeline
    subgraph CI_CD["CI/CD Pipeline (GitHub Actions)"]
        GitHub["GitHub Repository"]
        Checkout["Checkout Code"]
        AWSCreds["Configure AWS Credentials"]
        DockerBuild["Build Docker Image"]
        Trivy["Trivy Security Scan"]
        ECR["Push to AWS ECR"]
        Tag["Tag Latest Image"]
        UpdateLT["Update Launch Template"]
        ASGRefresh["ASG Instance Refresh"]
        GitHub --> Checkout
        Checkout --> AWSCreds
        AWSCreds --> DockerBuild
        DockerBuild --> Trivy
        Trivy --> ECR
        ECR --> Tag
        Tag --> UpdateLT
        UpdateLT --> ASGRefresh
    end
    style GitHub fill:#eaf6fb,stroke:#333
    style Checkout fill:#eaf6fb,stroke:#333
    style AWSCreds fill:#eaf6fb,stroke:#333
    style DockerBuild fill:#eaf6fb,stroke:#333
    style Trivy fill:#f5b7b1,stroke:#333
    style ECR fill:#eaf6fb,stroke:#333
    style Tag fill:#eaf6fb,stroke:#333
    style UpdateLT fill:#eaf6fb,stroke:#333
    style ASGRefresh fill:#eaf6fb,stroke:#333

    %% AWS VPC
    subgraph VPC["AWS VPC (devops-project-vpc)"]
        LB["Application Load Balancer"]
        TG["Target Group"]
        Bastion["Bastion Host (EC2)"]
        DB["RDS PostgreSQL"]
        S3["S3 (Static/Media Files, optional)"]

        subgraph ASG["Auto Scaling Group"]
            EC2A["App Server (EC2-1)"]
            EC2B["App Server (EC2-2)"]
        end

        LB --> TG
        TG --> EC2A
        TG --> EC2B
        Bastion --> EC2A
        Bastion --> EC2B
        EC2A --> DB
        EC2B --> DB
        EC2A --> S3
        EC2B --> S3
        LB -->|Health Check| EC2A
        LB -->|Health Check| EC2B
    end
    style VPC fill:#e8f8f5,stroke:#333,stroke-width:2px
    style LB fill:#d5f5e3,stroke:#333
    style TG fill:#d5f5e3,stroke:#333
    style ASG fill:#d4efdf,stroke:#333,stroke-dasharray: 5 5
    style EC2A fill:#d5f5e3,stroke:#333
    style EC2B fill:#d5f5e3,stroke:#333
    style Bastion fill:#f7ca18,stroke:#333
    style DB fill:#f9e79f,stroke:#333
    style S3 fill:#aed6f1,stroke:#333

    %% Flows
    User --> LB
    Admin --> Bastion
    ASGRefresh --> EC2A
    ASGRefresh --> EC2B

    %% Admin Panel
    User -->|/admin/| LB
```

---

## CI/CD Pipeline Details

- **Build:** Docker image is built from the Django source code.
- **Scan:** Trivy scans the image for vulnerabilities (pipeline fails on CRITICAL/HIGH).
- **Push:** Secure image is pushed to AWS ECR.
- **Deploy:** Launch template is updated and ASG triggers instance refresh for zero-downtime deployment.

---

## Usage

1. **Clone the repository** and review the Terraform files.
2. **Configure AWS credentials** and run `terraform apply` to provision infrastructure.
3. **Push code changes** to GitHub to trigger CI/CD and deploy updates.
4. **Access the ecommerce app** via the ALB DNS name.
5. **Manage products** via the Django admin panel (`/admin/`).

---

## Author

Leney Gannasan (ami3g)
Email: amitesh3000@yahoo.com

---
