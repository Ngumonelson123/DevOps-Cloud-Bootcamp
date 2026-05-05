# Fetch available AZs in the configured region
data "aws_availability_zones" "available" {
  state = "available"
}

# Fetch current AWS account details
data "aws_caller_identity" "current" {}

# Fetch latest Amazon Linux 2 AMI dynamically
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Use provided AMI or fall back to latest Amazon Linux 2
locals {
  resolved_ami = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}
