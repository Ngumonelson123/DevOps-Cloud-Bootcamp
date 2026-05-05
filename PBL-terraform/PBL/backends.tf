terraform {
  backend "s3" {
    bucket       = "pbl-terraform-state-400844546140-2026"
    key          = "pbl/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
