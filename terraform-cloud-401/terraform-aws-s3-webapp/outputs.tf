# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "endpoint" {
  description = "Website endpoint URL for the S3 static site"
  value       = aws_s3_bucket_website_configuration.bucket.website_endpoint
}

output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.bucket.id
}
