# ============================================================
#  OUTPUTS  –  Useful values printed after terraform apply
# ============================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "external_alb_dns" {
  description = "DNS name of the internet-facing ALB (point your domain here)"
  value       = module.alb.external_alb_dns
}

output "internal_alb_dns" {
  description = "DNS name of the internal ALB"
  value       = module.alb.internal_alb_dns
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.rds_endpoint
}

output "efs_id" {
  description = "EFS file system ID"
  value       = module.efs.efs_id
}

output "bastion_eips" {
  description = "Elastic IPs assigned to Bastion hosts"
  value       = module.compute.bastion_eips
}

output "wordpress_url" {
  description = "WordPress website URL"
  value       = "https://${var.domain_name}"
}

output "tooling_url" {
  description = "Tooling website URL"
  value       = "https://tooling.${var.domain_name}"
}
