##############################################################
# StegHub Terraform 401 — Terraform Cloud
# Root configuration — consumes the private s3-webapp module
##############################################################

module "s3_webapp" {
  # ── After publishing to your Private Registry, replace source with: ──
  # source  = "app.terraform.io/YOUR_ORG_NAME/s3-webapp/aws"
  # version = "1.0.0"

  # ── Local path used for initial dev/testing ──────────────────
  source = "./terraform-aws-s3-webapp"

  region = var.aws_region
  prefix = var.prefix
  name   = var.name
}

# ─── VPC (from Public Module Registry) ───────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.common_tags
}

# ─── Security Group ──────────────────────────────────────────
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-web-sg" })
}

# ─── EC2 Instance (from Private Module Registry) ─────────────
module "compute" {
  source = "./modules/terraform-aws-compute"

  ami_id          = var.ami_id
  instance_type   = var.instance_type
  instance_name   = "${var.project_name}-server"
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.web_sg.id]
  key_name        = var.key_name

  tags = local.common_tags
}

# ─── S3 Bucket (for app assets) ──────────────────────────────
resource "aws_s3_bucket" "app_assets" {
  bucket = "${var.project_name}-assets-${random_string.suffix.result}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
