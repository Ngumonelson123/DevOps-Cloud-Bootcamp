##############################################################
# backend.tf
# Replace ORG_NAME and WORKSPACE_NAME with your values
##############################################################

terraform {
  cloud {
    organization = "YOUR_ORG_NAME" # e.g. "nelson-steghub"

    workspaces {
      name = "terraform-cloud-dev" # change per environment
    }
  }

  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
