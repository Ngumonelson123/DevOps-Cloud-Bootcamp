##############################################################
# locals.tf
##############################################################

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform-cloud"
    Owner       = "nelson"
  }
}

##############################################################
# provider.tf
##############################################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
