# ============================================================
#  outputs.tf — Key outputs after terraform apply
# ============================================================

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer — paste this in your browser"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "rds_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = module.rds.rds_endpoint
  sensitive   = true
}

output "efs_dns_name" {
  description = "EFS DNS name for mounting inside EC2 instances"
  value       = module.efs.efs_dns_name
}

output "efs_id" {
  description = "EFS File System ID"
  value       = module.efs.efs_id
}

output "launch_template_id" {
  description = "ID of the EC2 Launch Template"
  value       = module.compute.launch_template_id
}

output "aws_account_id" {
  description = "AWS Account ID being deployed to"
  value       = data.aws_caller_identity.current.account_id
}
