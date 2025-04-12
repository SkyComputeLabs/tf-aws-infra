# tf-aws-infra

# AWS Infrastructure with Terraform

This project provisions AWS infrastructure using Terraform. It includes:
- A VPC with public and private subnets
- An Internet Gateway for public access
- Route tables to manage networking

## Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (v1.x.x or later)
- AWS CLI (configured with credentials)
- A valid AWS account with necessary permissions

## Setup Instructions

# AWS CLI command to import SSL Certificate (Demo Environment)
aws acm import-certificate \
  --certificate fileb://path/to/domain.crt \
  --private-key fileb://path/to/private-key.key \
  --certificate-chain fileb://path/to/ca-bundle.crt \
  --region us-east-2

### 1. Clone the Repository
```sh
git clone <repository_url>
cd tf-aws-infra

terraform init
terraform validate
terraform apply-auto-approve-var="ami_id=<your-ami-id>"

## Best Practices
- Always use `terraform plan` before `terraform apply`.
- Do not commit `.terraform` or state files to Git.
- Use remote state management for collaboration.

