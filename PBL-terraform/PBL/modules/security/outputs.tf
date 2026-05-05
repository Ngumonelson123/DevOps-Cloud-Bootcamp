output "alb_sg_id" {
  description = "Security Group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "Security Group ID for the EC2 app instances"
  value       = aws_security_group.app.id
}

output "rds_sg_id" {
  description = "Security Group ID for the RDS database"
  value       = aws_security_group.rds.id
}

output "efs_sg_id" {
  description = "Security Group ID for the EFS mount targets"
  value       = aws_security_group.efs.id
}
