# terraform-aws-s3-webapp

A Terraform module that deploys a static web application to an S3 bucket with public website hosting enabled. Ships with the **Terramino** game (Tetris clone) as the default web app.

> This module is published to your Terraform Cloud **Private Module Registry**.

---

## Usage (after publishing to Private Registry)

```hcl
module "s3_webapp" {
  source  = "app.terraform.io/YOUR_ORG_NAME/s3-webapp/aws"
  version = "1.0.0"

  region = "us-east-1"
  prefix = "nelson-steghub"
  name   = "webapp"
}

output "website_url" {
  value = module.s3_webapp.endpoint
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| region | AWS region | string | us-east-1 | no |
| prefix | Bucket name prefix | string | — | yes |
| name | Bucket name suffix | string | webapp | no |

## Outputs

| Name | Description |
|---|---|
| endpoint | S3 website endpoint URL |
| bucket_name | Name of the S3 bucket |
