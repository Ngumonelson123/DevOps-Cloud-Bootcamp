terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Uncomment this block AFTER you create the S3 bucket manually
  backend "s3" {
    bucket  = "nelson-ngumo-terraform-state-2025"
    key     = "reverse-proxy/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Automated   = "Yes"
      ManagedBy   = "Terraform"
    }
  }
}
