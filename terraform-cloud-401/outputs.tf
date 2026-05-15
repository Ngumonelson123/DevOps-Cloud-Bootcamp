##############################################################
# outputs.tf
##############################################################

output "website_url" {
  description = "URL of the deployed S3 static website (Terramino game)"
  value       = "http://${module.s3_webapp.endpoint}"
}

output "s3_webapp_bucket" {
  description = "S3 bucket name for the webapp"
  value       = module.s3_webapp.bucket_name
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "web_instance_id" {
  description = "EC2 instance ID"
  value       = module.compute.instance_id
}

output "web_instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.compute.public_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 assets bucket"
  value       = aws_s3_bucket.app_assets.bucket
}
